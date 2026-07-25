<?php

return [
    'duffel' => [
        'token'   => env('DUFFEL_TOKEN', ''),
        'version' => env('DUFFEL_VERSION', 'v2'),
        'base'    => 'https://api.duffel.com',
        'timeout' => (int) env('DUFFEL_TIMEOUT', 15),
    ],

    'travelpayouts' => [
        'token'   => env('TRAVELPAYOUTS_TOKEN', ''),
        'timeout' => (int) env('TRAVELPAYOUTS_TIMEOUT', 15),
        // Partner marker untuk redirect_link fallback
        'marker'  => env('TRAVELPAYOUTS_MARKER', ''),
    ],

    'staff' => [
        'panel_key' => env('STAFF_PANEL_KEY', ''),
    ],

    'clerk' => [
        'secret_key'     => env('CLERK_SECRET_KEY', ''),
        'webhook_secret' => env('CLERK_WEBHOOK_SECRET', ''),
        // Endpoint JWKS Clerk untuk verifikasi signature JWT session token.
        // Format: https://<frontend-api>/.well-known/jwks.json
        'jwks_url'       => env('CLERK_JWKS_URL', ''),
    ],

    // Secret untuk OrderHashService (HMAC-SHA256). WAJIB diisi di .env,
    // jangan pernah hardcode. Kalau bocor, semua order hash bisa dipalsukan.
    'order_hash' => [
        'secret' => env('ORDER_HASH_SECRET', ''),
    ],

    // Floor amount minimal untuk charge paket (interim, cegah manipulasi harga
    // ke nominal sangat kecil). Ganti/naikkan sesuai harga paket termurah.
    'package' => [
        'min_amount' => (int) env('PACKAGE_MIN_AMOUNT', 50000),
    ],

    // Resend (email via HTTPS API). Dipakai karena Railway memblokir port SMTP
    // keluar (465/587 timeout). Set MAIL_MAILER=resend + RESEND_API_KEY di env.
    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],
];
