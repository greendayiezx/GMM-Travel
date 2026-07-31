<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * CorsMiddleware
 * --------------
 * Menambahkan header CORS ke SEMUA response API dan menangani preflight
 * (OPTIONS) langsung, sehingga Flutter Web / SPA dari origin mana pun bisa
 * memanggil API tanpa diblokir browser.
 *
 * Aman karena autentikasi memakai Bearer token di header (bukan cookie
 * lintas-situs), jadi `Access-Control-Allow-Origin: *` tidak membocorkan
 * kredensial.
 */
class CorsMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $request->isMethod('OPTIONS')
            ? new Response('', 204)
            : $next($request);

        $origin = $request->headers->get('Origin');

        // Izinkan SEMUA origin. Kalau ada Origin dikirim, pantulkan balik
        // (dengan Vary: Origin) agar tetap bekerja di semua kasus.
        if ($origin) {
            $response->headers->set('Access-Control-Allow-Origin', $origin);
            $response->headers->set('Vary', 'Origin');
        } else {
            $response->headers->set('Access-Control-Allow-Origin', '*');
        }

        $response->headers->set(
            'Access-Control-Allow-Methods',
            'GET, POST, PUT, PATCH, DELETE, OPTIONS'
        );
        $response->headers->set(
            'Access-Control-Allow-Headers',
            'Content-Type, Authorization, Accept, X-Requested-With, X-Staff-Key'
        );
        $response->headers->set('Access-Control-Max-Age', '86400');

        return $response;
    }
}
