<?php

namespace App\Services;

use App\Models\FlightBooking;
use App\Models\TourBooking;
use App\Models\TravelBooking;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * LoyaltyService
 * --------------
 * Menghitung ringkasan loyalitas (poin & tier) dari transaksi NYATA user dalam
 * 12 bulan terakhir. Versi read-model: poin diturunkan dari booking valid,
 * belum ada ledger/penukaran/expiry (itu fase berikutnya). Parameter di
 * config/loyalty.php. Referensi: docs/skema-loyalitas-poin-membership.md.
 */
class LoyaltyService
{
    private const TIER_ORDER = ['blue', 'silver', 'gold', 'platinum'];

    private const TIER_LABEL = [
        'blue'     => 'Blue',
        'silver'   => 'Silver',
        'gold'     => 'Gold',
        'platinum' => 'Platinum',
    ];

    /** Ringkasan loyalitas lengkap untuk kartu profil. */
    public function forUser(User $user): array
    {
        $since = Carbon::now()->subYear();
        $rates = config('loyalty.earn_rp_per_point');
        $valid = config('loyalty.valid_status');

        $flightSpend = (float) FlightBooking::where('user_id', $user->id)
            ->whereIn('status', $valid['flight'])
            ->where('created_at', '>=', $since)
            ->sum('total_amount');

        $shuttleSpend = (float) TravelBooking::where('user_id', $user->id)
            ->whereIn('status', $valid['shuttle'])
            ->where('created_at', '>=', $since)
            ->sum('total_amount');

        $tourSpend = (float) TourBooking::where('user_id', $user->id)
            ->whereIn('status', $valid['tour'])
            ->where('created_at', '>=', $since)
            ->sum('total_amount');

        $spend12m = $flightSpend + $shuttleSpend + $tourSpend;

        // Poin dasar (1x) per produk sesuai earning rate.
        $points = intdiv((int) $flightSpend, max(1, (int) $rates['flight']))
            + intdiv((int) $shuttleSpend, max(1, (int) $rates['shuttle']))
            + intdiv((int) $tourSpend, max(1, (int) $rates['tour']));

        [$tier, $next, $progress, $remaining, $threshold] =
            $this->tierProgress($spend12m);

        return [
            'tier'                => $tier,
            'tier_label'          => self::TIER_LABEL[$tier],
            'points_balance'      => $points,
            'spend_12m'           => (int) $spend12m,
            'next_tier'           => $next,
            'next_tier_label'     => $next ? self::TIER_LABEL[$next] : null,
            'next_tier_threshold' => $threshold,
            'remaining_to_next'   => $remaining,
            'progress_pct'        => $progress,
        ];
    }

    /** Poin saja (dipakai endpoint /me/stats). */
    public function pointsForUser(User $user): int
    {
        return (int) $this->forUser($user)['points_balance'];
    }

    /**
     * Tentukan tier + progres menuju tier berikutnya.
     *
     * @return array{0:string,1:?string,2:int,3:int,4:?int}
     *         [tier, nextTier, progressPct, remainingRp, nextThreshold]
     */
    private function tierProgress(float $spend): array
    {
        $t = config('loyalty.tier_thresholds');
        $floors = [
            'blue'     => 0,
            'silver'   => (int) $t['silver'],
            'gold'     => (int) $t['gold'],
            'platinum' => (int) $t['platinum'],
        ];

        $tier = 'blue';
        foreach (self::TIER_ORDER as $name) {
            if ($spend >= $floors[$name]) {
                $tier = $name;
            }
        }

        if ($tier === 'platinum') {
            return ['platinum', null, 100, 0, null];
        }

        $idx = (int) array_search($tier, self::TIER_ORDER, true);
        $next = self::TIER_ORDER[$idx + 1];
        $currentFloor = $floors[$tier];
        $nextThreshold = $floors[$next];

        $band = max(1, $nextThreshold - $currentFloor);
        $progress = (int) round((($spend - $currentFloor) / $band) * 100);
        $progress = max(0, min(100, $progress));
        $remaining = (int) max(0, $nextThreshold - $spend);

        return [$tier, $next, $progress, $remaining, $nextThreshold];
    }
}
