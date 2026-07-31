<?php

// Origin frontend yang diizinkan. Set CORS_ALLOWED_ORIGINS di .env production
// dengan domain asli (pisahkan koma bila lebih dari satu), mis:
//   CORS_ALLOWED_ORIGINS=https://gmmglobalexplore.com,https://www.gmmglobalexplore.com
$envOrigins = array_values(array_filter(array_map('trim', explode(',', (string) env('CORS_ALLOWED_ORIGINS', '')))));

// Gabungan: domain production dari .env + FRONTEND_URL bila diset.
$allowedOrigins = array_values(array_filter(array_merge($envOrigins, array_filter([env('FRONTEND_URL')]))));

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],

    // Jika tidak ada origin spesifik dikonfigurasi, izinkan SEMUA origin.
    // Aman karena autentikasi memakai Bearer token (header), bukan cookie
    // lintas-situs (supports_credentials => false di bawah).
    'allowed_origins' => $allowedOrigins === [] ? ['*'] : $allowedOrigins,

    // Localhost (termasuk IPv6) & ngrok tetap diizinkan untuk development,
    // khususnya Flutter Web yang memakai port acak (flutter run -d chrome).
    'allowed_origins_patterns' => [
        '#^http://localhost(:\d+)?$#',
        '#^http://127\.0\.0\.1(:\d+)?$#',
        '#^http://\[::1\](:\d+)?$#',
        '#^https://.*\.ngrok-free\.app$#',
    ],

    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,

    // Kita pakai Bearer token (Authorization header), bukan cookie lintas-situs,
    // jadi credentials tidak perlu.
    'supports_credentials' => false,
];
