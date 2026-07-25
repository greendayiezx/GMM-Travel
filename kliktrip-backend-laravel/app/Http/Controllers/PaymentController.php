<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Services\BookingService;
use App\Services\PaymentService;
use App\Services\MidtransService;
use App\Services\PackagePricingService;
use App\Services\OrderHashService;
use App\Models\PackageOrder;
use App\Models\User;
use App\Models\Payment;
use App\Http\Resources\PaymentResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class PaymentController extends Controller
{
    // Konstanta Status Pembayaran (Database Enums)
    const PAYMENT_PENDING = 'PENDING';
    const PAYMENT_SUCCESS = 'SUCCESS';
    const PAYMENT_FAILED = 'FAILED';
    const PAYMENT_EXPIRED = 'EXPIRED';
    const PAYMENT_REFUNDED = 'REFUNDED';

    // Konstanta Status Booking (Database Enums)
    const BOOKING_PENDING = 'PENDING';
    const BOOKING_PAID = 'PAID';
    const BOOKING_EXPIRED = 'EXPIRED';
    const BOOKING_CANCELLED = 'CANCELLED';

    protected BookingService $bookingService;
    protected PaymentService $paymentService;
    protected MidtransService $midtransService;
    protected PackagePricingService $packagePricing;
    protected OrderHashService $orderHash;

    public function __construct(
        BookingService $bookingService,
        PaymentService $paymentService,
        MidtransService $midtransService,
        PackagePricingService $packagePricing,
        OrderHashService $orderHash
    ) {
        $this->bookingService = $bookingService;
        $this->paymentService = $paymentService;
        $this->midtransService = $midtransService;
        $this->packagePricing = $packagePricing;
        $this->orderHash = $orderHash;
    }

    /**
     * Generate Midtrans Snap token untuk package payment page.
     * Dipanggil dari Angular: POST /api/charge
     */
    public function packageCharge(Request $request)
    {
        $request->validate([
            'orderId'       => ['required', 'string', 'max:64'],
            'amount'        => ['required', 'integer', 'min:1'],
            'customerName'  => ['required', 'string', 'max:255'],
            'customerEmail' => ['nullable', 'email'],
            'packageName'   => ['nullable', 'string', 'max:255'],
            'items'         => ['nullable', 'array', 'max:20'],
            'items.*.name'  => ['required_with:items', 'string', 'max:100'],
            'items.*.qty'   => ['required_with:items', 'integer', 'min:0', 'max:50'],
        ]);

        $user        = $request->user();
        $clientAmount = (int) $request->input('amount');
        $packageName  = $request->input('packageName');
        $items        = $request->input('items', []);

        // ── VALIDASI HARGA SERVER-SIDE (anti price manipulation) ──────
        // Backend TIDAK mempercayai `amount` dari client. Harga dihitung ulang
        // dari katalog paket di DB (package_catalogs), lalu dibandingkan.
        $pkg          = $this->packagePricing->find($packageName);
        $chargeAmount = $clientAmount; // nominal final yang benar-benar di-charge

        if ($pkg) {
            if (!empty($items)) {
                // Rincian tiket ada → hitung total pasti dari harga DB.
                $expected = $this->packagePricing->computeExpectedTotal($pkg, $items);
                if ($expected === null || $expected <= 0) {
                    return response()->json(['message' => 'Rincian pesanan tidak valid.'], 422);
                }
                if ($clientAmount !== $expected) {
                    Log::warning('Price manipulation terdeteksi', [
                        'user_id'      => optional($user)->id,
                        'package_name' => $packageName,
                        'client_amount'=> $clientAmount,
                        'server_amount'=> $expected,
                        'ip'           => $request->ip(),
                    ]);
                    return response()->json(['message' => 'Harga tidak sesuai. Silakan muat ulang halaman.'], 422);
                }
                // Pakai nilai server (sudah dipastikan = expected).
                $chargeAmount = $expected;
            } else {
                // Tanpa rincian tiket → minimal harus >= tiket termurah paket ini.
                $floor = $this->packagePricing->minTicketPrice($pkg);
                if ($clientAmount < $floor) {
                    Log::warning('Amount di bawah floor paket', [
                        'user_id'      => optional($user)->id,
                        'package_name' => $packageName,
                        'client_amount'=> $clientAmount,
                        'floor'        => $floor,
                        'ip'           => $request->ip(),
                    ]);
                    return response()->json(['message' => 'Harga tidak sesuai. Silakan muat ulang halaman.'], 422);
                }
            }
        } else {
            // Paket tidak ada di katalog (belum ter-seed / paket baru).
            // Jangan tolak total (agar tidak merusak), tapi terapkan floor global + log.
            $globalFloor = (int) config('services.package.min_amount', 50000);
            if ($clientAmount < $globalFloor) {
                return response()->json(['message' => 'Harga tidak sesuai.'], 422);
            }
            Log::warning('Charge paket di luar katalog', [
                'user_id'      => optional($user)->id,
                'package_name' => $packageName,
                'amount'       => $clientAmount,
            ]);
        }

        // Persist order paket ke DB (sebelumnya tidak disimpan). Kini order
        // punya identitas + pemilik → bisa dilindungi order hash & cek kepemilikan.
        $order = PackageOrder::updateOrCreate(
            ['order_code' => (string) $request->input('orderId')],
            [
                'user_id'      => $user->id,
                'package_name' => $packageName ?: 'Paket Wisata GMM Travel',
                'total_amount' => $chargeAmount,
                'items'        => $items ?: null,
                'status'       => self::PAYMENT_PENDING,
            ]
        );

        // Order hash terikat ke (order.id + user.id) → URL detail/status paket
        // tidak bisa diakses user lain (anti-IDOR).
        $orderHash = $this->orderHash->generate((string) $order->id, (string) $user->id);

        Log::info('Package charge', [
            'user_id'      => $user->id,
            'order_id'     => $order->id,
            'order_code'   => $order->order_code,
            'amount'       => $chargeAmount,
            'package_name' => $packageName,
            'ip'           => $request->ip(),
        ]);

        try {
            $coreMethod = $this->normalizeCoreMethod($request->input('paymentMethod', 'bni_va'));

            $result = $this->midtransService->charge(
                $request->input('orderId'),
                (float) $chargeAmount,
                $coreMethod,
                [
                    'name'  => $request->input('customerName', 'Customer'),
                    'phone' => $request->input('customerPhone', '08000000000'),
                ],
                [
                    'id'       => 'PKG-' . $request->input('orderId'),
                    'price'    => $chargeAmount,
                    'quantity' => 1,
                    'name'     => $packageName ?: 'Paket Wisata GMM Travel',
                ]
            );

            return response()->json([
                'success'      => true,
                'order_id'     => $order->id,   // UUID order (untuk status/detail)
                'order_hash'   => $orderHash,   // tanda tangan anti-IDOR
                'payment_type' => $result['payment_type'],
                'instructions' => $result['instructions'],
                'expired_at'   => $result['expired_at'],
                'sandbox'      => $result['sandbox'] ?? false,
            ]);
        } catch (\Throwable $e) {
            Log::error('Package charge gagal', [
                'error' => $e->getMessage(),
                'file'  => $e->getFile() . ':' . $e->getLine(),
                'order_id' => $request->input('orderId'),
            ]);
            return response()->json(['message' => 'Gagal memproses pembayaran. Coba lagi.'], 500);
        }
    }

    private function normalizeCoreMethod(string $method): string
    {
        return match ($method) {
            'bca_va'     => 'bca',
            'bni_va'     => 'bni',
            'bri_va'     => 'bri',
            'mandiri_va' => 'mandiri',
            'permata_va' => 'permata',
            'bsi_va'     => 'bni',       // BSI pakai other_va, tapi di sandbox dimap ke bni
            'blu'        => 'bca',
            'klikbca'    => 'bca',
            'cc'         => 'gopay',     // credit card tidak ada di Core API sandbox, fallback QR
            'shopeepay'  => 'gopay',
            'dana'       => 'gopay',
            'akulaku'    => 'gopay',
            'kredivo'    => 'gopay',
            default      => $method,     // gopay, qris, dll langsung
        };
    }

    public function charge(Request $request)
    {
        $request->validate([
            'schedule_id' => ['required', 'uuid', 'exists:travel_schedules,id'],
            'seat_number' => ['required', 'string'],
            'passenger_name' => ['required', 'string', 'min:3'],
            'passenger_phone' => ['required', 'string', 'min:9'],
            'payment_method' => ['required', 'string'],
        ]);

        return DB::transaction(function () use ($request) {
            // Pembeli = user yang identitasnya sudah diverifikasi middleware
            // clerk.auth. Booking WAJIB tertaut ke user asli ini agar cek
            // kepemilikan (di status/simulateSuccess) bermakna dan aman dari IDOR.
            $user = $request->user();
            if (!$user) {
                return response()->json(['message' => 'Unauthorized'], 401);
            }

            // 1. Buat Travel Booking
            $passengersData = [
                [
                    'name' => $request->input('passenger_name'),
                    'seat_number' => $request->input('seat_number'),
                    'identity_number' => $request->input('passenger_phone'),
                ]
            ];

            $booking = $this->bookingService->createTravelBooking(
                $user->id,
                $request->input('schedule_id'),
                $passengersData
            );

            // 2. Inisiasi data tagihan lokal
            $method = strtoupper($request->input('payment_method'));
            if ($method === 'BNI') $methodCode = 'BNI_VA';
            elseif ($method === 'BRI') $methodCode = 'BRI_VA';
            elseif ($method === 'MANDIRI') $methodCode = 'MANDIRI_VA';
            else $methodCode = $method;

            $payment = $this->paymentService->initiatePayment($booking->id, 'TRAVEL', $methodCode);

            // 3. Kirim ke Midtrans API
            $customer = [
                'name' => $request->input('passenger_name'),
                'phone' => $request->input('passenger_phone'),
            ];

            $item = [
                'id' => $booking->travelSchedule->id,
                'price' => (int) $booking->travelSchedule->price,
                'quantity' => 1,
                'name' => "Tiket " . $booking->travelSchedule->travelRoute->departureCity->name . " ke " . $booking->travelSchedule->travelRoute->arrivalCity->name,
            ];

            // Panggil Midtrans Service
            $midtransResult = $this->midtransService->charge(
                $payment->invoice_number,
                $payment->total_amount,
                $request->input('payment_method'),
                $customer,
                $item
            );

            // 4. Update data pembayaran lokal
            $payment->gateway_transaction_id = $midtransResult['transaction_id'];
            $payment->payment_instructions   = $midtransResult['instructions'];
            $payment->expired_at             = $midtransResult['expired_at'];
            $payment->save();

            return response()->json([
                'success'      => true,
                'booking_code' => $booking->booking_code,
                'payment_type' => $midtransResult['payment_type'],
                'instructions' => $midtransResult['instructions'],
                'sandbox'      => $midtransResult['sandbox'] ?? false,
                'payment'      => new PaymentResource($payment),
            ]);
        });
    }

    public function simulateSuccess(Request $request, string $id)
    {
        // KEAMANAN KRITIS: endpoint ini menandai pembayaran LUNAS tanpa transaksi
        // asli. Hanya boleh ada di lingkungan development/sandbox. Di production ia
        // akan menjadi lubang "bypass pembayaran" (booking gratis), jadi diblokir.
        if (app()->environment('production')) {
            abort(404);
        }

        $payment = \App\Models\Payment::findOrFail($id);

        // Meski hanya untuk sandbox, tetap pastikan hanya pemilik yang bisa
        // menandai pembayarannya sendiri (konsisten dengan proteksi status).
        if (!$this->ownsPayment($request, $payment)) {
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        if ($payment->status !== self::PAYMENT_PENDING) {
            return response()->json(['message' => 'Payment sudah diproses.'], 422);
        }

        $payment->status                 = self::PAYMENT_SUCCESS;
        $payment->gateway_transaction_id = 'sim-' . now()->timestamp;
        $payment->paid_at                = now();
        $payment->save();

        $booking = $payment->payable;
        if ($booking) {
            $booking->status = self::BOOKING_PAID;
            $booking->save();
        }

        return response()->json(['success' => true, 'status' => self::PAYMENT_SUCCESS]);
    }

    public function notification(Request $request)
    {
        $orderId = $request->input('order_id');
        $statusCode = $request->input('status_code');
        $grossAmount = $request->input('gross_amount');
        $serverKey = config('midtrans.server_key');
        $signatureKey = $request->input('signature_key');

        $localSignature = hash('sha512', $orderId . $statusCode . $grossAmount . $serverKey);

        if ($localSignature !== $signatureKey) {
            return response()->json(['message' => 'Signature key tidak valid.'], 403);
        }

        return DB::transaction(function () use ($request) {
            $invoiceNumber = $request->input('order_id');
            $transactionStatus = $request->input('transaction_status');
            $gatewayTransactionId = $request->input('transaction_id');

            $payment = Payment::where('invoice_number', $invoiceNumber)->first();

            if (!$payment) {
                return response()->json(['message' => 'Invoice payment tidak ditemukan.'], 404);
            }

            // Catat log payload
            $payment->paymentLogs()->create([
                'raw_payload' => $request->all(),
                'status' => $transactionStatus,
                'description' => "Callback received from Midtrans: status {$transactionStatus}",
            ]);

            // Pemetaan Status Midtrans ke Database Enums
            $paymentStatus  = self::PAYMENT_PENDING;
            $bookingStatus  = self::BOOKING_PENDING;
            $paidAt         = null;
            $releaseSeats   = false; // tandai apakah kursi perlu dikembalikan

            switch ($transactionStatus) {
                case 'capture':
                    $fraudStatus = $request->input('fraud_status');
                    if ($fraudStatus === 'accept') {
                        $paymentStatus = self::PAYMENT_SUCCESS;
                        $bookingStatus = self::BOOKING_PAID;
                        $paidAt        = now();
                    } else {
                        // fraud_status: 'challenge' atau 'deny' — tolak transaksi
                        $paymentStatus = self::PAYMENT_FAILED;
                        $bookingStatus = self::BOOKING_CANCELLED;
                        $releaseSeats  = true;
                    }
                    break;

                case 'settlement':
                    $paymentStatus = self::PAYMENT_SUCCESS;
                    $bookingStatus = self::BOOKING_PAID;
                    $paidAt        = now();
                    break;

                case 'pending':
                    // Tidak ada perubahan, biarkan PENDING
                    break;

                case 'deny':
                case 'cancel':
                    $paymentStatus = self::PAYMENT_FAILED;
                    $bookingStatus = self::BOOKING_CANCELLED;
                    $releaseSeats  = true;
                    break;

                case 'expire':
                    $paymentStatus = self::PAYMENT_EXPIRED;
                    $bookingStatus = self::BOOKING_EXPIRED;
                    $releaseSeats  = true;
                    break;

                case 'refund':
                case 'partial_refund':
                case 'chargeback':
                    $paymentStatus = self::PAYMENT_REFUNDED;
                    $bookingStatus = self::BOOKING_CANCELLED;
                    // Kursi sudah terlanjur PAID sebelumnya — tidak di-release
                    // karena perjalanan sudah dianggap terjadi, hanya refund uang
                    break;
            }

            // Update status tabel payments
            $payment->status                 = $paymentStatus;
            $payment->gateway_transaction_id = $gatewayTransactionId;
            if ($paidAt) {
                $payment->paid_at = $paidAt;
            }
            $payment->save();

            // Update status tabel travel_bookings + pelepasan kursi
            $booking = $payment->payable;
            if ($booking) {
                $booking->status = $bookingStatus;
                $booking->save();

                // Kembalikan kursi ke pool jika booking dibatalkan/expired/gagal
                if ($releaseSeats && $booking->travelSchedule) {
                    $passengerCount = $booking->travelPassengers()->count();
                    if ($passengerCount > 0) {
                        $booking->travelSchedule->increment('available_seats', $passengerCount);
                    }
                }
            }

            return response()->json(['success' => true]);
        });
    }

    public function status(Request $request, string $id)
    {
        $payment = Payment::findOrFail($id);

        // Proteksi IDOR: pastikan pembayaran ini milik user yang login.
        // Tanpa cek ini, siapa pun yang tahu id pembayaran bisa membaca
        // status milik orang lain.
        if (!$this->ownsPayment($request, $payment)) {
            Log::warning('Akses status pembayaran ditolak (IDOR)', [
                'ip'         => $request->ip(),
                'user_id'    => optional($request->user())->id,
                'payment_id' => $id,
            ]);
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        return response()->json([
            'status' => $payment->status,
            'paid_at' => $payment->paid_at?->toIso8601String(),
        ]);
    }

    /**
     * Cek apakah $payment milik user yang sedang login.
     * Payment bersifat polimorfik (payable = TravelBooking/TourBooking/
     * FlightBooking), semuanya punya kolom user_id.
     */
    private function ownsPayment(Request $request, Payment $payment): bool
    {
        $user = $request->user();
        if (!$user) {
            return false;
        }
        $booking = $payment->payable;
        return $booking && (string) $booking->user_id === (string) $user->id;
    }
}
