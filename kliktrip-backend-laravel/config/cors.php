<?php

// Origin frontend yang diizinkan. Set CORS_ALLOWED_ORIGINS di .env production
// dengan domain asli (pisahkan koma bila lebih dari satu), mis:
//   CORS_ALLOWED_ORIGINS=https://gmmglobalexplore.com,https://www.gmmglobalexplore.com
$envOrigins = array_filter(array_map('trim', explode(',', (string) env('CORS_ALLOWED_ORIGINS', ''))));

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],

    // Gabungan: domain production dari .env + FRONTEND_URL bila diset.
    'allowed_origins' => array_values(array_filter(array_merge(
        $envOrigins,
        array_filter([env('FRONTEND_URL')]),
    ))),

    // Localhost & ngrok tetap diizinkan untuk development (pola regex).
    'allowed_origins_patterns' => [
        '#^http://localhost:\d+$#',
        '#^http://127\.0\.0\.1:\d+$#',
        '#^https://.*\.ngrok-free\.app$#',
    ],

    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,

    // Kita pakai Bearer token (Authorization header), bukan cookie lintas-situs,
    // jadi credentials tidak perlu.
    'supports_credentials' => false,
];
