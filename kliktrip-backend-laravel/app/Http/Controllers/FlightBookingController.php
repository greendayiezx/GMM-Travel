<?php

namespace App\Http\Controllers;

use App\Models\FlightBooking;
use App\Models\Payment;
use App\Services\FlightBookingService;
use App\Services\PaymentService;
use App\Services\MidtransService;
use App\Services\DuffelService;
use App\Http\Resources\PaymentResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class FlightBookingController extends Controller
{
    public function __construct(
        protected FlightBookingService $flightBookingService,
        protected PaymentService $paymentService,
        protected MidtransService $midtransService,
        protected DuffelService $duffelService
    ) {}

    public function charge(Request $request)
    {
        $request->validate([
            'flight_data'              => ['required', 'array'],
            'flight_data.airline'      => ['required', 'string'],
            'flight_data.flightNumber' => ['required', 'string'],
            'flight_data.origin'       => ['required', 'string'],
            'flight_data.destination'  => ['required', 'string'],
            'flight_data.price'        => ['required', 'numeric', 'min:1'],
            'passengers'               => ['required', 'array', 'min:1'],
            'passengers.*.title'         => ['required', 'string'],
            'passengers.*.full_name'     => ['required', 'string', 'min:3'],
            'passengers.*.date_of_birth' => ['required', 'date'],
            'passengers.*.id_type'       => ['required', 'string'],
            'passengers.*.id_number'     => ['required', 'string'],
            'passengers.*.phone'         => ['required', 'string', 'min:9'],
            'passengers.*.email'         => ['required', 'email'],
            'passengers.*.passenger_type'=> ['required', 'string'],
            'payment_method'           => ['required', 'string'],
        ]);

        // Wajib login (dipaksa middleware clerk.auth). Booking harus tertaut ke
        // user asli agar terlindungi cek kepemilikan di status().
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        // ── RE-PRICING SERVER-SIDE (anti manipulasi harga flight) ─────
        // Untuk offer Duffel (id diawali "off_"), harga TIDAK dipercaya dari
        // client. Kita ambil ulang harga terkini langsung dari Duffel. Bila
        // offer sudah kadaluarsa/tak tersedia → tolak, user harus cari ulang.
        $flightData = $request->input('flight_data');
        $offerId    = (string) ($flightData['id'] ?? '');

        if (str_starts_with($offerId, 'off_')) {
            $serverPrice = $this->duffelService->getOfferPriceIdr($offerId);
            if ($serverPrice === null) {
                return response()->json([
                    'message' => 'Harga penerbangan telah berubah atau tidak lagi tersedia. Silakan cari ulang.',
                ], 422);
            }
            // Duffel total_amount = harga total offer (semua penumpang) →
            // dipakai langsung sebagai total, bukan dikali jumlah penumpang.
            if ((int) ($flightData['price'] ?? 0) !== $serverPrice) {
                Log::warning('Harga flight client != Duffel (di-override server)', [
                    'offer_id'      => $offerId,
                    'client_price'  => $flightData['price'] ?? null,
                    'server_price'  => $serverPrice,
                    'user_id'       => $user->id,
                ]);
            }
            $flightData['price'] = $serverPrice;
        }

        return DB::transaction(function () use ($request, $user, $flightData, $offerId) {
            $passengersData = $request->input('passengers');
            $passengerCount = count($passengersData);

            // Duffel: total = harga offer (sudah mencakup semua penumpang).
            // Non-Duffel: pertahankan perilaku lama (harga × jumlah penumpang).
            $totalAmount = str_starts_with($offerId, 'off_')
                ? (float) $flightData['price']
                : (float) $flightData['price'] * $passengerCount;

            $booking = $this->flightBookingService->createFlightBooking(
                $user->id,
                $flightData,
                $passengersData,
                $totalAmount
            );

            $method = strtoupper($request->input('payment_method'));
            $methodCode = match ($method) {
                'BNI'     => 'BNI_VA',
                'BRI'     => 'BRI_VA',
                'MANDIRI' => 'MANDIRI_VA',
                default   => $method,
            };

            $payment = $this->paymentService->initiatePayment($booking->id, 'FLIGHT', $methodCode);

            $firstPassenger = $passengersData[0];
            $customer = [
                'name'  => $firstPassenger['full_name'],
                'phone' => $firstPassenger['phone'],
                'email' => $firstPassenger['email'] ?? '',
            ];

            $item = [
                'id'       => $flightData['flightNumber'] ?? 'FLT',
                'price'    => (int) $flightData['price'],
                'quantity' => $passengerCount,
                'name'     => "Tiket Pesawat " . ($flightData['origin'] ?? '') . " → " . ($flightData['destination'] ?? ''),
            ];

            $midtransResult = $this->midtransService->charge(
                $payment->invoice_number,
                $payment->total_amount,
                $request->input('payment_method'),
                $customer,
                $item
            );

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

    public function status(Request $request, string $code)
    {
        $booking = FlightBooking::where('booking_code', $code)
            ->with(['flightPassengers', 'flightTicketFiles', 'payment'])
            ->firstOrFail();

        // Proteksi IDOR: hanya pemilik booking yang boleh melihat statusnya.
        $user = $request->user();
        if (!$user || (string) $booking->user_id !== (string) $user->id) {
            Log::warning('Akses status flight booking ditolak (IDOR)', [
                'ip'           => $request->ip(),
                'user_id'      => optional($user)->id,
                'booking_code' => $code,
            ]);
            return response()->json(['message' => 'Akses ditolak.'], 403);
        }

        $ticketUrl = null;
        if ($booking->status === 'ISSUED' && $booking->flightTicketFiles->isNotEmpty()) {
            $ticketUrl = asset('storage/' . $booking->flightTicketFiles->first()->file_path);
        }

        return response()->json([
            'booking_code' => $booking->booking_code,
            'status'       => $booking->status,
            'flight_data'  => $booking->flight_data,
            'passengers'   => $booking->flightPassengers,
            'ticket_url'   => $ticketUrl,
            'total_amount' => $booking->total_amount,
            'created_at'   => $booking->created_at?->toIso8601String(),
        ]);
    }
}
