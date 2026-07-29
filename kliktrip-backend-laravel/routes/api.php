<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ClerkWebhookController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\TravelScheduleController;
use App\Http\Controllers\FlightBookingController;
use App\Http\Controllers\FlightSearchController;
use App\Http\Controllers\StaffController;
use App\Models\TravelSchedule;

// ── Health Check ──────────────────────────────────────────────
Route::get('/health', fn() => response()->json(['status' => 'ok']));

// ── Clerk Webhooks ────────────────────────────────────────────
Route::post('/clerk/webhook', [ClerkWebhookController::class, 'handle']);

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
    return response()->json(
        TravelSchedule::with(['travelRoute.departureCity', 'travelRoute.arrivalCity'])
            ->get(['id', 'travel_route_id', 'departure_time', 'price', 'available_seats', 'status'])
    );
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
