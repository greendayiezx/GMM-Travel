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
    public function forUser(?User $user): array
    {
        if (!$user) {
            return $this->defaultLoyaltyData();
        }

        try {
            $since = Carbon::now()->subYear();
            $rates = config('loyalty.earn_rp_per_point');
            $valid = config('loyalty.valid_status');

            $flightSpend = (float) FlightBooking::where('user_id', $user->id)
                ->whereIn('status', $valid['flight'] ?? ['PAID', 'ISSUED'])
                ->where('created_at', '>=', $since)
                ->sum('total_amount');

            $shuttleSpend = (float) TravelBooking::where('user_id', $user->id)
                ->whereIn('status', $valid['shuttle'] ?? ['PAID'])
                ->where('created_at', '>=', $since)
                ->sum('total_amount');

            $tourSpend = (float) TourBooking::where('user_id', $user->id)
                ->whereIn('status', $valid['tour'] ?? ['PAID'])
                ->where('created_at', '>=', $since)
                ->sum('total_amount');

            $spend12m = $flightSpend + $shuttleSpend + $tourSpend;

            // Poin dasar (1x) per produk sesuai earning rate.
            $ratesFlight = max(1, (int) ($rates['flight'] ?? 2000));
            $ratesShuttle = max(1, (int) ($rates['shuttle'] ?? 200));
            $ratesTour = max(1, (int) ($rates['tour'] ?? 100));

            $points = intdiv((int) $flightSpend, $ratesFlight)
                + intdiv((int) $shuttleSpend, $ratesShuttle)
                + intdiv((int) $tourSpend, $ratesTour);

            [$tier, $next, $progress, $remaining, $threshold] =
                $this->tierProgress($spend12m);

            return [
                'tier'                => $tier,
                'tier_label'          => self::TIER_LABEL[$tier] ?? 'Blue',
                'points_balance'      => $points,
                'spend_12m'           => (int) $spend12m,
                'next_tier'           => $next,
                'next_tier_label'     => $next ? (self::TIER_LABEL[$next] ?? null) : null,
                'next_tier_threshold' => $threshold,
                'remaining_to_next'   => $remaining,
                'progress_pct'        => $progress,
            ];
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('LoyaltyService error: ' . $e->getMessage());
            return $this->defaultLoyaltyData();
        }
    }

    public function defaultLoyaltyData(): array
    {
        return [
            'tier'                => 'blue',
            'tier_label'          => 'Blue',
            'points_balance'      => 0,
            'spend_12m'           => 0,
            'next_tier'           => 'silver',
            'next_tier_label'     => 'Silver',
            'next_tier_threshold' => 5000000,
            'remaining_to_next'   => 5000000,
            'progress_pct'        => 0,
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
