<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * SecurityHeaders
 * ---------------
 * Menambahkan HTTP security header ke SEMUA response. Header ini bekerja di
 * level browser sebagai lapisan pertahanan tambahan terhadap XSS, clickjacking,
 * MIME sniffing, dan kebocoran informasi.
 */
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        /** @var Response $response */
        $response = $next($request);

        // Cegah XSS dengan CSP. Alih-alih 'self' polos (yang akan memblokir
        // Clerk, Midtrans, Google Fonts saat SPA disajikan lewat Laravel di
        // production), kita allowlist HANYA domain pihak ketiga yang benar-benar
        // dipakai aplikasi. Ini tetap ketat tapi tidak merusak fungsionalitas.
        $csp = implode('; ', [
            "default-src 'self'",
            // Script: app sendiri + Clerk (CDN unpkg & frontend API) + Midtrans + Google.
            // 'unsafe-inline'/'unsafe-eval' diperlukan Angular & SDK pihak ketiga.
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://*.clerk.accounts.dev https://*.clerk.com https://unpkg.com https://*.midtrans.com https://*.veritrans.co.id https://www.googletagmanager.com https://pay.google.com",
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
            "font-src 'self' data: https://fonts.gstatic.com",
            "img-src 'self' data: blob: https:",
            // Koneksi API: backend sendiri + Clerk + Midtrans + Travelpayouts/Duffel.
            "connect-src 'self' https://*.clerk.accounts.dev https://*.clerk.com https://*.midtrans.com https://api.travelpayouts.com https://api.duffel.com",
            // Iframe pembayaran Midtrans & widget Clerk.
            "frame-src 'self' https://*.midtrans.com https://*.veritrans.co.id https://*.clerk.accounts.dev https://challenges.cloudflare.com",
            "worker-src 'self' blob:",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
            "frame-ancestors 'none'",
        ]);
        $response->headers->set('Content-Security-Policy', $csp);

        // Cegah clickjacking: halaman tidak boleh di-embed dalam <iframe>.
        $response->headers->set('X-Frame-Options', 'DENY');

        // Cegah MIME sniffing: browser wajib menghormati Content-Type asli.
        $response->headers->set('X-Content-Type-Options', 'nosniff');

        // Paksa HTTPS selama 1 tahun (termasuk subdomain).
        // Hanya efektif & aman dikirim saat koneksi sudah HTTPS.
        if ($request->isSecure()) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains'
            );
        }

        // Jangan bocorkan URL asal saat user berpindah ke situs lain.
        $response->headers->set('Referrer-Policy', 'no-referrer');

        // Matikan fitur browser sensitif yang tidak dipakai.
        $response->headers->set(
            'Permissions-Policy',
            'geolocation=(), microphone=(), camera=()'
        );

        // Sembunyikan detail server/framework (kurangi info untuk attacker).
        $response->headers->remove('X-Powered-By');
        $response->headers->remove('Server');

        return $response;
    }
}
