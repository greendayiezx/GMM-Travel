<?php

namespace App\Http\Controllers;

use App\Models\FlightBooking;
use App\Models\PaymentMethod;
use App\Models\SavedPassenger;
use App\Services\LoyaltyService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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
}
