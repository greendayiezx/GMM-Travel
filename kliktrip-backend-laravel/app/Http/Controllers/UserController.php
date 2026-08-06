<?php

namespace App\Http\Controllers;

use App\Mail\DataExportMail;
use App\Models\Favorite;
use App\Models\FlightBooking;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\Payment;
use App\Models\PaymentMethod;
use App\Models\PromoClaim;
use App\Models\SavedCard;
use App\Models\SavedPassenger;
use App\Models\TourCatalog;
use App\Services\LoyaltyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Validator;

/**
 * UserController
 * --------------
 * Data profil user yang login (identitas Clerk sudah diverifikasi oleh
 * middleware `clerk.auth`, jadi $request->user() dijamin user asli).
 */
class UserController extends Controller
{
    /**
     * GET /me/stats
     * Statistik nyata untuk halaman profil app mobile.
     *
     * - trips   : jumlah seluruh booking milik user (travel + tour + flight)
     * - reviews : jumlah review yang ditulis user
     * - points  : saldo poin loyalitas nyata (dihitung dari transaksi)
     */
    public function stats(Request $request, LoyaltyService $loyalty): JsonResponse
    {
        $user = $request->user();

        $trips = $user->travelBookings()->count()
            + $user->tourBookings()->count()
            + FlightBooking::where('user_id', $user->id)->count();

        return response()->json([
            'name'    => $user->name,
            'email'   => $user->email,
            'avatar'  => $user->avatar,
            'trips'   => $trips,
            'points'  => $loyalty->pointsForUser($user),
            'reviews' => $user->reviews()->count(),
        ]);
    }

    /**
     * GET /me/loyalty
     * Ringkasan tier & progres loyalitas untuk kartu "Loyalty Status" di profil
     * (tier, saldo poin, belanja 12 bulan, progres ke tier berikutnya).
     */
    public function loyalty(Request $request, LoyaltyService $loyalty): JsonResponse
    {
        return response()->json($loyalty->forUser($request->user()));
    }

    /**
     * GET /me/bookings
     * Daftar booking NYATA milik user yang login, diagregasi dari semua jenis
     * booking (flight + shuttle + wisata) & diurutkan terbaru dulu.
     */
    public function bookings(Request $request): JsonResponse
    {
        $user = $request->user();

        $items = [];

        // Flight bookings
        $flights = FlightBooking::where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->get();
        foreach ($flights as $b) {
            $flight = $b->flight_data ?? [];
            $items[] = [
                'category'   => 'flight',
                'code'       => $b->booking_code,
                'title'      => trim(($flight['origin'] ?? '') . ' → ' . ($flight['destination'] ?? '')),
                'status'     => $b->status,
                'date'       => $flight['departureDate']
                    ?? ($b->created_at?->toDateString() ?? date('Y-m-d')),
                'price'      => (float) $b->total_amount,
                'created_at' => $b->created_at?->toIso8601String(),
            ];
        }

        // Shuttle (travel) bookings
        $shuttles = $user->travelBookings()
            ->with(['travelSchedule.travelRoute.departureCity', 'travelSchedule.travelRoute.arrivalCity'])
            ->orderByDesc('created_at')
            ->get();
        foreach ($shuttles as $b) {
            $schedule = $b->travelSchedule;
            $route    = $schedule?->travelRoute;
            $items[] = [
                'category'   => 'shuttle',
                'code'       => $b->booking_code,
                'title'      => trim(
                    ($route?->departureCity?->name ?? '') . ' → ' . ($route?->arrivalCity?->name ?? '')
                ),
                'status'     => $b->status,
                'date'       => $schedule?->departure_time?->toDateString() ?? $b->created_at?->toDateString(),
                'price'      => (float) $b->total_amount,
                'created_at' => $b->created_at?->toIso8601String(),
            ];
        }

        // Wisata (tour) bookings
        $tours = $user->tourBookings()
            ->with(['tourSchedule.tourPackage'])
            ->orderByDesc('created_at')
            ->get();
        foreach ($tours as $b) {
            $schedule = $b->tourSchedule;
            $package  = $schedule?->tourPackage;
            $items[] = [
                'category'   => 'wisata',
                'code'       => $b->booking_code,
                'title'      => $package?->name ?? 'Paket Wisata',
                'status'     => $b->status,
                'date'       => $schedule?->departure_date?->toDateString() ?? $b->created_at?->toDateString(),
                'price'      => (float) $b->total_amount,
                'created_at' => $b->created_at?->toIso8601String(),
            ];
        }

        // Urutkan dari yang terbaru
        usort($items, fn ($a, $b) => strcmp($b['created_at'] ?? '', $a['created_at'] ?? ''));

        return response()->json($items);
    }

    /**
     * GET /me/passengers
     * Daftar penumpang tersimpan milik user (Saved Passenger Data).
     */
    public function passengers(Request $request): JsonResponse
    {
        $list = $request->user()->savedPassengers()
            ->orderByDesc('is_primary')
            ->orderBy('created_at')
            ->get();

        return response()->json($list);
    }

    /**
     * POST /me/passengers
     * Simpan data penumpang baru milik user.
     */
    public function storePassenger(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'title'            => ['required', 'string', 'max:10'],
            'full_name'        => ['required', 'string', 'max:120'],
            'category'         => ['nullable', 'string', 'max:20'],
            'identity_number'  => ['required', 'string', 'max:30'],
            'passport_number'  => ['nullable', 'string', 'max:30'],
            'gender'           => ['nullable', 'string', 'max:20'],
            'birth_date'       => ['nullable', 'string', 'max:30'],
            'is_primary'       => ['nullable', 'boolean'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = $request->user();
        $data = $validator->validated();
        $data['user_id'] = $user->id;
        $data['is_primary'] = (bool) ($data['is_primary'] ?? false);

        // Hanya satu penumpang primer per user — set yang lain jadi non-primer.
        if ($data['is_primary']) {
            $user->savedPassengers()->update(['is_primary' => false]);
        }

        $passenger = SavedPassenger::create($data);

        return response()->json($passenger, 201);
    }

    /**
     * DELETE /me/passengers/{id}
     * Hapus penumpang tersimpan (dengan cek kepemilikan anti-IDOR).
     */
    public function deletePassenger(Request $request, string $id): JsonResponse
    {
        $passenger = SavedPassenger::where('user_id', $request->user()->id)->findOrFail($id);
        $passenger->delete();

        return response()->json(['success' => true]);
    }

    /**
     * GET /me/saved-cards
     * Daftar kartu pembayaran tersimpan milik user. Hanya mengembalikan
     * field yang aman ditampilkan — saved_token_id TIDAK PERNAH dikirim
     * balik ke client karena app tidak butuh nilai itu lagi setelah kartu
     * berhasil didaftarkan.
     */
    public function savedCards(Request $request): JsonResponse
    {
        $cards = $request->user()->savedCards()
            ->orderByDesc('is_default')
            ->orderByDesc('created_at')
            ->get(['id', 'masked_card', 'card_type', 'bank', 'is_default', 'created_at']);

        return response()->json($cards);
    }

    /**
     * POST /me/saved-cards
     * Simpan referensi kartu yang SUDAH ditokenisasi Midtrans langsung dari
     * device (lihat MidtransCardRegisterDataSource di app mobile). Endpoint
     * ini hanya menerima saved_token_id + masked_card — nomor kartu mentah
     * tidak pernah melewati backend ini sama sekali.
     */
    public function storeSavedCard(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'saved_token_id' => ['required', 'string', 'max:100'],
            'masked_card'    => [
                'required', 'string', 'max:30',
                function ($attribute, $value, $fail) {
                    // Pertahanan berlapis: tolak kalau nilainya menyerupai
                    // nomor kartu mentah (13-19 digit tanpa karakter mask).
                    if (preg_match('/^\d{13,19}$/', $value)) {
                        $fail('Format masked_card tidak valid (menyerupai nomor kartu mentah).');
                        return;
                    }
                    if (!preg_match('/[-* ]/', $value)) {
                        $fail('masked_card wajib berupa nomor kartu yang sudah di-mask.');
                    }
                },
            ],
            'card_type'      => ['nullable', 'string', 'max:20'],
            'bank'           => ['nullable', 'string', 'max:30'],
            'is_default'     => ['nullable', 'boolean'],
            // Kalau field ini terkirim (sengaja atau tidak), tolak keras —
            // backend ini tidak boleh pernah menerima data kartu mentah.
            'card_number'    => ['prohibited'],
            'cvv'            => ['prohibited'],
            'card_cvv'       => ['prohibited'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $user = $request->user();
        $data = $validator->validated();
        unset($data['card_number'], $data['cvv'], $data['card_cvv']);
        $data['user_id'] = $user->id;
        $data['gateway'] = 'MIDTRANS';
        $data['is_default'] = (bool) ($data['is_default'] ?? false);

        if ($data['is_default']) {
            $user->savedCards()->update(['is_default' => false]);
        }

        $card = SavedCard::create($data);

        return response()->json([
            'id'          => $card->id,
            'masked_card' => $card->masked_card,
            'card_type'   => $card->card_type,
            'bank'        => $card->bank,
            'is_default'  => $card->is_default,
        ], 201);
    }

    /**
     * DELETE /me/saved-cards/{id}
     */
    public function deleteSavedCard(Request $request, string $id): JsonResponse
    {
        $card = SavedCard::where('user_id', $request->user()->id)->findOrFail($id);
        $card->delete();

        return response()->json(['success' => true]);
    }

    /**
     * GET /me/payment-methods
     * Channel pembayaran NYATA yang aktif (dari tabel payment_methods).
     */
    public function paymentMethods(Request $request): JsonResponse
    {
        $methods = PaymentMethod::where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'gateway', 'logo']);

        return response()->json($methods);
    }

    /**
     * GET /me/favorites
     * Daftar favorit NYATA milik user (polimorfik), dinormalisasi ke bentuk
     * ringkas yang bisa langsung dirender app mobile (SavedPage).
     */
    public function favorites(Request $request): JsonResponse
    {
        $favorites = $request->user()->favorites()
            ->latest()
            ->get();

        $items = $favorites->map(function ($favorite) {
            $target = $favorite->favoritable;

            if ($target instanceof \App\Models\TourPackage) {
                $image = $target->thumbnail;
                $firstImage = $target->tourImages()->first();
                if ($firstImage?->image_path) {
                    $image = $firstImage->image_path;
                }
                return [
                    'favorite_id' => $favorite->id,
                    'type'        => 'wisata',
                    'title'       => $target->name,
                    'subtitle'    => 'Paket Wisata',
                    'price'       => null,
                    'price_sub'   => 'Mulai dari',
                    'rating'      => null,
                    'image'       => $image,
                ];
            }

            if ($target instanceof \App\Models\TravelRoute) {
                return [
                    'favorite_id' => $favorite->id,
                    'type'        => 'shuttle',
                    'title'       => trim(
                        ($target->departureCity?->name ?? '') . ' → ' . ($target->arrivalCity?->name ?? '')
                    ),
                    'subtitle'    => 'Shuttle',
                    'price'       => null,
                    'price_sub'   => 'Mulai dari',
                    'rating'      => null,
                    'image'       => null,
                ];
            }

            if ($target instanceof \App\Models\TourCatalog) {
                $data = $target->payload ?? [];
                return [
                    'favorite_id' => $favorite->id,
                    'type'        => 'wisata',
                    // Dipakai app mobile mencocokkan ke WisataPackage.id dari GET /tours.
                    'item_id'     => $data['id'] ?? $target->external_id,
                    'title'       => $data['nama_paket'] ?? $target->nama_paket,
                    'subtitle'    => $data['destinasi'] ?? 'Paket Wisata',
                    // 'price' harus sudah dalam bentuk siap-tampil (mis.
                    // "Rp 7.899.000"), BUKAN angka mentah — Flutter menampilkan
                    // nilai ini apa adanya tanpa format ulang.
                    'price'       => $data['harga_display'] ?? null,
                    'price_sub'   => 'Mulai dari',
                    'rating'      => $data['rating'] ?? null,
                    'image'       => $data['gambar'] ?? null,
                ];
            }

            $name = $target instanceof \Illuminate\Database\Eloquent\Model
                ? ($target->getAttribute('name') ?? 'Favorit')
                : 'Favorit';
            return [
                'favorite_id' => $favorite->id,
                'type'        => 'generic',
                'title'       => $name,
                'subtitle'    => '',
                'price'       => null,
                'price_sub'   => null,
                'rating'      => null,
                'image'       => null,
            ];
        });

        return response()->json($items);
    }

    /**
     * POST /me/export-data
     * Kirim ringkasan data pribadi user ke email terdaftar (permintaan
     * "unduh data saya" ala GDPR). Dikirim SINKRON (bukan queue) karena
     * Railway tidak menjalankan queue worker — lihat komentar di WelcomeMail.
     */
    public function exportData(Request $request): JsonResponse
    {
        $user = $request->user();

        try {
            $data = [
                'profile' => [
                    'name'       => $user->name,
                    'email'      => $user->email,
                    'phone'      => $user->phone,
                    'joined_at'  => $user->created_at?->toIso8601String(),
                ],
                'travel_bookings_count'  => $user->travelBookings()->count(),
                'tour_bookings_count'    => $user->tourBookings()->count(),
                'favorites_count'        => $user->favorites()->count(),
                'saved_passengers'       => $user->savedPassengers()
                    ->get(['full_name', 'identity_number', 'passport_number']),
                // saved_token_id sengaja TIDAK disertakan — hanya info tampilan aman.
                'saved_cards'            => $user->savedCards()
                    ->get(['masked_card', 'card_type', 'bank', 'created_at']),
            ];

            Mail::to($user->email)->send(new DataExportMail($user->name, $user->email, $data));

            return response()->json(['success' => true]);
        } catch (\Throwable $e) {
            Log::error('Gagal mengirim data export', ['user_id' => $user->id, 'error' => $e->getMessage()]);
            return response()->json(['message' => 'Gagal mengirim data. Coba lagi nanti.'], 500);
        }
    }

    /**
     * DELETE /me/account
     * Hapus akun secara PERMANEN: user Clerk dihapus dulu lewat Backend API
     * (pola sama seperti perintah `users:purge`), baru kalau itu berhasil
     * data lokal dihapus. Urutan ini sengaja — supaya tidak pernah ada
     * kondisi "data lokal hilang tapi akun Clerk masih bisa login".
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->clerk_id) {
            $secret = config('services.clerk.secret_key');
            $resp = Http::withToken($secret)->timeout(20)
                ->delete("https://api.clerk.com/v1/users/{$user->clerk_id}");

            // 404 berarti user Clerk memang sudah tidak ada — anggap sukses.
            if (!$resp->successful() && $resp->status() !== 404) {
                Log::error('Gagal menghapus user Clerk saat hapus akun', [
                    'user_id' => $user->id,
                    'clerk_id' => $user->clerk_id,
                    'status'  => $resp->status(),
                ]);
                return response()->json(['message' => 'Gagal menghapus akun. Coba lagi nanti.'], 500);
            }
        }

        DB::transaction(function () use ($user) {
            $bookingIds = collect()
                ->merge($user->travelBookings()->pluck('id'))
                ->merge($user->tourBookings()->pluck('id'))
                ->merge(FlightBooking::where('user_id', $user->id)->pluck('id'));

            if ($bookingIds->isNotEmpty()) {
                Payment::whereIn('payable_id', $bookingIds)->delete();
            }

            // flight_bookings tidak punya FK constraint ke users, jadi tidak
            // otomatis cascade — hapus manual.
            FlightBooking::where('user_id', $user->id)->delete();

            // Sisanya (travel_bookings, tour_bookings, favorites, reviews,
            // voucher_usages, notifications, notification_logs,
            // notification_preferences, package_orders, saved_passengers,
            // saved_cards) otomatis cascadeOnDelete lewat FK saat baris user
            // dihapus di bawah ini.
            $user->delete();
        });

        return response()->json(['success' => true]);
    }

    /**
     * GET /me/notification-settings
     * Preferensi notifikasi user (App Settings di mobile). Bila belum ada
     * record, dibuat dengan default (sama dengan default lokal di mobile).
     */
    public function notificationSettings(Request $request): JsonResponse
    {
        $prefs = NotificationPreference::firstOrCreate(
            ['user_id' => $request->user()->id],
            $this->defaultNotificationPreferences(),
        );

        return response()->json($this->formatNotificationPreferences($prefs));
    }

    /**
     * PUT /me/notification-settings
     * Simpan preferensi notifikasi user. Mengembalikan preferensi terbaru.
     */
    public function updateNotificationSettings(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'push_notifications' => 'required|boolean',
            'email_promos'       => 'required|boolean',
            'order_updates'      => 'required|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Data preferensi tidak valid.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $prefs = NotificationPreference::updateOrCreate(
            ['user_id' => $request->user()->id],
            [
                'push_notifications' => $request->boolean('push_notifications'),
                'email_promos'       => $request->boolean('email_promos'),
                'order_updates'      => $request->boolean('order_updates'),
            ],
        );

        return response()->json($this->formatNotificationPreferences($prefs));
    }

    private function defaultNotificationPreferences(): array
    {
        return [
            'push_notifications' => true,
            'email_promos'       => false,
            'order_updates'      => true,
        ];
    }

    private function formatNotificationPreferences(NotificationPreference $prefs): array
    {
        return [
            'push_notifications' => $prefs->push_notifications,
            'email_promos'       => $prefs->email_promos,
            'order_updates'      => $prefs->order_updates,
        ];
    }

    /**
     * POST /me/favorites
     * Simpan item (paket wisata, dll) ke favorit. Idempotent — dipanggil
     * dobel untuk item yang sama tidak membuat baris duplikat (firstOrCreate
     * + unique index di migration).
     */
    public function storeFavorite(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'type'    => ['required', 'string', 'in:wisata'],
            'item_id' => ['required', 'string', 'max:64'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $data = $validator->validated();
        $user = $request->user();

        // Saat ini hanya 'wisata' (TourCatalog) yang didukung sebagai favoritable.
        $catalog = TourCatalog::where('payload->id', $data['item_id'])
            ->orWhere('external_id', $data['item_id'])
            ->first();

        if (!$catalog) {
            return response()->json(['message' => 'Paket tidak ditemukan.'], 404);
        }

        $favorite = Favorite::firstOrCreate([
            'user_id'          => $user->id,
            'favoritable_id'   => $catalog->id,
            'favoritable_type' => TourCatalog::class,
        ]);

        $payload = $catalog->payload ?? [];

        return response()->json([
            'favorite_id' => $favorite->id,
            'type'        => 'wisata',
            'item_id'     => $payload['id'] ?? $catalog->external_id,
            'title'       => $payload['nama_paket'] ?? $catalog->nama_paket,
            'subtitle'    => $payload['destinasi'] ?? 'Paket Wisata',
            'price'       => $payload['harga_display'] ?? null,
            'price_sub'   => 'Mulai dari',
            'rating'      => $payload['rating'] ?? null,
            'image'       => $payload['gambar'] ?? null,
        ], 201);
    }

    /**
     * DELETE /me/favorites/{id}
     */
    public function destroyFavorite(Request $request, string $id): JsonResponse
    {
        $favorite = Favorite::where('user_id', $request->user()->id)->findOrFail($id);
        $favorite->delete();

        return response()->json(['success' => true]);
    }

    /**
     * GET /me/promo-claims
     * Daftar item_id paket promo yang sudah diklaim user — dipakai mobile
     * menentukan paket promo mana yang harganya sudah "terbuka" (diskon)
     * untuk user ini.
     */
    public function promoClaims(Request $request): JsonResponse
    {
        $itemIds = PromoClaim::where('user_id', $request->user()->id)
            ->with('tourCatalog:id,payload,external_id')
            ->get()
            ->map(fn ($claim) => $claim->tourCatalog?->payload['id']
                ?? $claim->tourCatalog?->external_id)
            ->filter()
            ->values();

        return response()->json($itemIds);
    }

    /**
     * POST /me/promo-claims
     * Klaim satu paket promo. Cuma paket dengan is_promo=true di payload-nya
     * yang bisa diklaim — mencegah user "klaim" paket biasa buat cari diskon
     * yang tidak seharusnya ada.
     */
    public function storePromoClaim(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'item_id' => ['required', 'string', 'max:64'],
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => $validator->errors()->first()], 422);
        }

        $itemId = $validator->validated()['item_id'];
        $catalog = TourCatalog::where('payload->id', $itemId)
            ->orWhere('external_id', $itemId)
            ->first();

        if (!$catalog) {
            return response()->json(['message' => 'Paket tidak ditemukan.'], 404);
        }

        if (($catalog->payload['is_promo'] ?? false) !== true) {
            return response()->json(['message' => 'Paket ini bukan promo.'], 422);
        }

        $claim = PromoClaim::firstOrCreate(
            ['user_id' => $request->user()->id, 'tour_catalog_id' => $catalog->id],
            ['claimed_at' => now()],
        );

        return response()->json([
            'item_id'    => $itemId,
            'claimed_at' => $claim->claimed_at,
        ], 201);
    }

    /**
     * GET /me/notifications
     */
    public function notifications(Request $request): JsonResponse
    {
        $list = $request->user()->notifications()
            ->latest()
            ->get(['id', 'title', 'message', 'read_at', 'created_at']);

        return response()->json($list);
    }

    /**
     * POST /me/notifications/{id}/read
     */
    public function markNotificationRead(Request $request, string $id): JsonResponse
    {
        $notification = Notification::where('user_id', $request->user()->id)->findOrFail($id);
        if (!$notification->read_at) {
            $notification->update(['read_at' => now()]);
        }

        return response()->json(['success' => true]);
    }
}
