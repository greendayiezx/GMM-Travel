<?php

use Illuminate\Support\Str;

return [

    /*
    |--------------------------------------------------------------------------
    | Default Session Driver
    |--------------------------------------------------------------------------
    */
    'driver' => env('SESSION_DRIVER', 'file'),

    /*
    | Lifetime — maksimal 120 menit (spesifikasi keamanan). Session kadaluarsa
    | otomatis agar sesi yang tercuri tidak berlaku selamanya.
    */
    'lifetime' => env('SESSION_LIFETIME', 120),

    // Session ikut berakhir saat browser ditutup (opsional; aktifkan bila perlu).
    'expire_on_close' => env('SESSION_EXPIRE_ON_CLOSE', false),

    // Enkripsi payload session di storage.
    'encrypt' => env('SESSION_ENCRYPT', true),

    'files' => storage_path('framework/sessions'),

    'connection' => env('SESSION_CONNECTION'),
    'table' => env('SESSION_TABLE', 'sessions'),
    'store' => env('SESSION_STORE'),
    'lottery' => [2, 100],

    /*
    |--------------------------------------------------------------------------
    | Session Cookie
    |--------------------------------------------------------------------------
    */
    'cookie' => env(
        'SESSION_COOKIE',
        Str::slug(env('APP_NAME', 'laravel'), '_') . '_session'
    ),

    'path' => env('SESSION_PATH', '/'),
    'domain' => env('SESSION_DOMAIN'),

    /*
    | secure = true → cookie HANYA dikirim lewat HTTPS. Mencegah cookie session
    | tersadap di jaringan (man-in-the-middle) pada koneksi HTTP biasa.
    | Default mengikuti env; WAJIB true di production.
    */
    'secure' => env('SESSION_SECURE_COOKIE', true),

    /*
    | http_only = true → cookie tidak bisa dibaca JavaScript (document.cookie).
    | Ini pertahanan kunci terhadap pencurian session via XSS.
    */
    'http_only' => env('SESSION_HTTP_ONLY', true),

    /*
    | same_site = strict → cookie tidak dikirim pada request lintas situs.
    | Mencegah CSRF yang mengandalkan cookie session ikut terbawa otomatis.
    */
    'same_site' => env('SESSION_SAME_SITE', 'strict'),

    // Partitioned cookie (CHIPS) — biarkan default.
    'partitioned' => env('SESSION_PARTITIONED_COOKIE', false),

];
