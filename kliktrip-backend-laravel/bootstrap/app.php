<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->prepend(\Illuminate\Http\Middleware\HandleCors::class);

        // Security headers ke SEMUA response (api & web) — proteksi level browser
        // terhadap XSS, clickjacking, MIME sniffing.
        $middleware->append(\App\Http\Middleware\SecurityHeaders::class);

        // Alias middleware agar bisa dipakai di route.
        $middleware->alias([
            // Verifikasi token Clerk → set $request->user() terverifikasi.
            'clerk.auth'  => \App\Http\Middleware\VerifyClerkToken::class,
            // Proteksi IDOR pada halaman order/payment/invoice.
            'order.hash'  => \App\Http\Middleware\VerifyOrderHash::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
