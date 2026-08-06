<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClerkWebhookController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\TravelScheduleController;
use App\Http\Controllers\FlightBookingController;
use App\Http\Controllers\FlightSearchController;
use App\Http\Controllers\StaffController;
use App\Http\Controllers\UserController;
use App\Models\TravelSchedule;
use App\Models\TourCatalog;

// ── Health Check ──────────────────────────────────────────────
Route::get('/health', fn() => response()->json(['status' => 'ok']));

// ── Katalog paket wisata (dipindah dari asset lokal ke backend) ─
// Mengembalikan paket dalam bentuk yang sama dengan model WisataPackage di
// mobile, plus tanggal_keberangkatan yang di-generate future saat request.
Route::get('/tours', function () {
    $q = TourCatalog::where('active', true);

    if ($cat = request('category')) {
        $cat = strtoupper($cat);
        if ($cat !== 'SEMUA') {
            $q->where('kategori', $cat);
        }
    }

    $items = $q->orderBy('nama_paket')->get()->map(function (TourCatalog $t) {
        $data = $t->payload;
        $data['id'] = $data['id'] ?? $t->external_id;
        $data['tanggal_keberangkatan'] =
            TourCatalog::generateDepartures($data['harga_display'] ?? '');
        return $data;
    });

    return response()->json($items);
});

// ── Profil user (wajib login Clerk) ───────────────────────────
// Statistik nyata untuk halaman profil app mobile (trips/points/reviews).
Route::get('/me/stats', [UserController::class, 'stats'])->middleware(['clerk.auth', 'throttle:60,1']);
// Ringkasan tier & progres loyalitas (kartu "Loyalty Status").
Route::get('/me/loyalty', [UserController::class, 'loyalty'])->middleware(['clerk.auth', 'throttle:60,1']);
// Daftar booking nyata milik user (flight + shuttle + wisata).
Route::get('/me/bookings', [UserController::class, 'bookings'])->middleware(['clerk.auth', 'throttle:60,1']);
// Penumpang tersimpan (Saved Passenger Data) milik user.
Route::get('/me/passengers',    [UserController::class, 'passengers'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/me/passengers',   [UserController::class, 'storePassenger'])->middleware(['clerk.auth', 'throttle:30,1']);
Route::delete('/me/passengers/{id}', [UserController::class, 'deletePassenger'])->middleware(['clerk.auth', 'throttle:30,1']);
// Channel pembayaran aktif (Payment Methods) — data nyata dari DB.
Route::get('/me/payment-methods', [UserController::class, 'paymentMethods'])->middleware(['clerk.auth', 'throttle:60,1']);
// Favorit milik user (SavedPage) — data nyata dari DB.
Route::get('/me/favorites', [UserController::class, 'favorites'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/me/favorites', [UserController::class, 'storeFavorite'])->middleware(['clerk.auth', 'throttle:30,1']);
Route::delete('/me/favorites/{id}', [UserController::class, 'destroyFavorite'])->middleware(['clerk.auth', 'throttle:30,1']);

Route::get('/me/promo-claims', [UserController::class, 'promoClaims'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/me/promo-claims', [UserController::class, 'storePromoClaim'])->middleware(['clerk.auth', 'throttle:30,1']);
// Notifikasi user (dibuat otomatis dari event pembayaran, lihat PaymentController::notification()).
Route::get('/me/notifications', [UserController::class, 'notifications'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/me/notifications/{id}/read', [UserController::class, 'markNotificationRead'])->middleware(['clerk.auth', 'throttle:60,1']);
// Kartu pembayaran tersimpan — hanya menerima token Midtrans hasil tokenisasi
// di device, tidak pernah nomor kartu mentah (lihat SavedCard/UserController).
Route::get('/me/saved-cards', [UserController::class, 'savedCards'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/me/saved-cards', [UserController::class, 'storeSavedCard'])->middleware(['clerk.auth', 'throttle:20,1']);
Route::delete('/me/saved-cards/{id}', [UserController::class, 'deleteSavedCard'])->middleware(['clerk.auth', 'throttle:30,1']);
// Ekspor data pribadi (dikirim ke email) & hapus akun permanen.
Route::post('/me/export-data', [UserController::class, 'exportData'])->middleware(['clerk.auth', 'throttle:5,60']);
Route::delete('/me/account', [UserController::class, 'deleteAccount'])->middleware(['clerk.auth', 'throttle:5,1']);
// Preferensi notifikasi (App Settings) — sumber kebenaran per akun.
Route::get('/me/notification-settings', [UserController::class, 'notificationSettings'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::put('/me/notification-settings', [UserController::class, 'updateNotificationSettings'])->middleware(['clerk.auth', 'throttle:30,1']);

// ── Clerk Webhooks ────────────────────────────────────────────
Route::post('/clerk-webhook', [ClerkWebhookController::class, 'handle']);

// ── Order/Invoice/Payment terproteksi (anti-IDOR) ─────────────
// clerk.auth  → identitas user diverifikasi kriptografis (token Clerk)
// order.hash  → order_hash di query diverifikasi + cek kepemilikan DB
// throttle    → batasi permintaan agar tidak bisa brute-force hash
Route::middleware(['clerk.auth', 'throttle:60,1'])->group(function () {
    // Buat signed URL (butuh login, tapi belum butuh order.hash).
    Route::get('/orders/{orderId}/signed-url', [OrderController::class, 'signedUrl']);

    // Halaman sensitif: order.hash membaca ?order_id=..&order_hash=..
    Route::middleware('order.hash')->group(function () {
        Route::get('/orders/detail',  [OrderController::class, 'show']);
        Route::get('/orders/invoice', [OrderController::class, 'invoice']);
        Route::get('/orders/payment', [OrderController::class, 'show']);
    });
});

// Pembuatan pembayaran paket: wajib login (attribution) + dibatasi rate.
Route::post('/charge', [PaymentController::class, 'packageCharge'])->middleware(['clerk.auth', 'throttle:20,1']);
// Charge paket dari APP MOBILE (tanpa Clerk — identifikasi via email).
Route::post('/mobile/package-charge', [PaymentController::class, 'mobilePackageCharge'])->middleware('throttle:20,1');
// Pembuatan pembayaran dibatasi: cegah spam charge / abuse.
// Pembuatan & pengecekan pembayaran travel WAJIB login (clerk.auth) agar
// booking tertaut ke user asli & terlindungi cek kepemilikan (anti-IDOR).
Route::post('/payments', [PaymentController::class, 'charge'])->middleware(['clerk.auth', 'throttle:20,1']);
Route::get('/payments/{id}/status', [PaymentController::class, 'status'])->middleware(['clerk.auth', 'throttle:60,1']);
Route::post('/payments/{id}/simulate-success', [PaymentController::class, 'simulateSuccess'])->middleware(['clerk.auth', 'throttle:20,1']);

// Webhook Midtrans — TIDAK boleh butuh auth (dipanggil server Midtrans, bukan user).
Route::post('/payments/notification', [PaymentController::class, 'notification']);

// Seat availability per jadwal (realtime dari DB)
Route::get('/travel-schedules/{scheduleId}/seats', [TravelScheduleController::class, 'seats']);

// ── Flight Search (proxy ke Travelpayouts) ────────────────────
Route::get('/flights/search', [FlightSearchController::class, 'search']);
Route::get('/flights/airports', [FlightSearchController::class, 'airports']);
Route::get('/flights/calendar', [FlightSearchController::class, 'calendar']);
Route::get('/flights/price-check', [FlightSearchController::class, 'priceCheck']);
Route::get('/flights/price-strip', [FlightSearchController::class, 'priceStrip']);

// ── Flight Booking & Payment ──────────────────────────────────
// Wajib login (clerk.auth): booking tertaut user asli + status dilindungi ownership.
Route::post('/flight-payments', [FlightBookingController::class, 'charge'])->middleware(['clerk.auth', 'throttle:20,1']);
Route::get('/flight-bookings/{code}/status', [FlightBookingController::class, 'status'])->middleware(['clerk.auth', 'throttle:60,1']);

// ── Staff Panel (dilindungi X-Staff-Key header) ───────────────
// throttle:10,1 → maksimal 10 request/menit per IP. Membatasi brute-force
// terhadap X-Staff-Key (surface autentikasi staff).
Route::prefix('staff')->middleware('throttle:10,1')->group(function () {
    Route::get('/flight-bookings',                    [StaffController::class, 'queue']);
    Route::get('/flight-bookings/all',                [StaffController::class, 'all']);
    Route::post('/flight-bookings/{code}/processing', [StaffController::class, 'startProcessing']);
    Route::post('/flight-bookings/{code}/ticket',     [StaffController::class, 'uploadTicket']);
    Route::post('/flight-bookings/{code}/failed',     [StaffController::class, 'markFailed']);
});

// Route sementara untuk cek data jadwal
Route::get('/schedules', function () {
    $q = TravelSchedule::with([
            'travelRoute.departureCity',
            'travelRoute.arrivalCity',
            'vehicle:id,name,type,capacity',
        ])
        ->select('id', 'travel_route_id', 'vehicle_id', 'departure_time', 'price', 'available_seats', 'status')
        ->orderBy('departure_time');

    // Filter per tanggal keberangkatan (mis. ?date=2026-08-02). Wajib dikirim
    // mobile agar hasil sesuai tanggal DAN payload tetap kecil.
    if ($date = request('date')) {
        $q->whereDate('departure_time', $date);
    } else {
        // Tanpa tanggal: batasi ke jadwal mendatang saja agar tak membengkak.
        $q->where('departure_time', '>=', now()->startOfDay())->limit(300);
    }

    return response()->json($q->get());
});

// ── Rute shuttle "populer" untuk halaman pencarian shuttle ─────
// Belum ada data booking/review asli (TravelBooking & Review masih kosong),
// jadi popularitas dihitung dari jumlah jadwal tersedia per rute (proxy
// paling jujur yang bisa dihitung dari data yang benar-benar ada), dan harga
// dari harga jadwal termurah — bukan angka rating/harga fiktif.
Route::get('/shuttle/popular-routes', function () {
    // Filter ">0 jadwal" dilakukan di PHP (bukan SQL having()) karena Postgres
    // tidak mengizinkan alias hasil withCount() dipakai di HAVING tanpa
    // GROUP BY. Tabel travel_routes cuma puluhan baris jadi ini tetap murah.
    $routes = \App\Models\TravelRoute::query()
        ->with(['departureCity:id,name', 'arrivalCity:id,name'])
        ->withCount(['travelSchedules as schedule_count' => function ($q) {
            $q->where('status', 'SCHEDULED')->where('departure_time', '>=', now());
        }])
        ->withMin(['travelSchedules as min_price' => function ($q) {
            $q->where('status', 'SCHEDULED')->where('departure_time', '>=', now());
        }], 'price')
        ->orderByDesc('schedule_count')
        ->get()
        ->filter(fn ($route) => $route->schedule_count > 0)
        ->take(6)
        ->values()
        ->map(fn ($route) => [
            'id' => $route->id,
            'departure_city' => $route->departureCity?->name ?? '',
            'arrival_city' => $route->arrivalCity?->name ?? '',
            'min_price' => $route->min_price !== null ? (int) round($route->min_price) : null,
            'schedule_count' => $route->schedule_count,
        ])
        ->values();

    return response()->json($routes);
});

// ── Cities untuk shuttle autocomplete ─────────────────────────
Route::get('/cities', function () {
    $query = request('q', '');
    
    if (empty(trim($query))) {
        return response()->json([]);
    }
    
    $cities = \App\Models\City::with('province')
        ->where('name', 'like', '%' . $query . '%')
        ->orWhereHas('province', function ($q) use ($query) {
            $q->where('name', 'like', '%' . $query . '%');
        })
        ->limit(10)
        ->get()
        ->map(fn($city) => [
            'id' => $city->id,
            'name' => $city->name,
            'province' => $city->province?->name ?? '',
            'displayName' => $city->name . ($city->province ? ', ' . $city->province->name : ''),
        ]);
    
    return response()->json($cities);
});
