<?php

/**
 * Konfigurasi program loyalitas (poin & tier).
 * Nilai mengacu dokumen docs/skema-loyalitas-poin-membership.md.
 * Semua bisa dioverride via .env tanpa ubah kode.
 */
return [
    // 1 poin = Rp berapa saat ditukar (untuk referensi/valuasi).
    'redeem_value_rp' => (int) env('LOYALTY_REDEEM_VALUE_RP', 1),

    // "Rp X = 1 poin" per produk (base rate, tanpa multiplier tier).
    // flight  → FlightBooking, shuttle → TravelBooking, tour → TourBooking.
    'earn_rp_per_point' => [
        'flight'  => (int) env('LOYALTY_EARN_FLIGHT', 2000),
        'shuttle' => (int) env('LOYALTY_EARN_SHUTTLE', 200),
        'tour'    => (int) env('LOYALTY_EARN_TOUR', 100),
    ],

    // Ambang total belanja 12 bulan (Rp) untuk naik tier.
    'tier_thresholds' => [
        'silver'   => (int) env('LOYALTY_TIER_SILVER', 5000000),
        'gold'     => (int) env('LOYALTY_TIER_GOLD', 15000000),
        'platinum' => (int) env('LOYALTY_TIER_PLATINUM', 40000000),
    ],

    // Status booking yang dihitung sebagai transaksi valid (lunas).
    'valid_status' => [
        'flight'  => ['PAID', 'ISSUED'],
        'shuttle' => ['PAID'],
        'tour'    => ['PAID'],
    ],
];
