<?php

namespace App\Http\Middleware;

use App\Models\Role;
use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * VerifyClerkToken
 * ----------------
 * Memverifikasi session token Clerk (JWT RS256) yang dikirim frontend lewat
 * header `Authorization: Bearer <token>`, lalu memuat User lokal yang cocok.
 *
 * Kenapa ini penting untuk security:
 * Sebelumnya backend "percaya" user_id yang dikirim frontend. Itu berbahaya —
 * siapa pun bisa mengaku sebagai user lain. Middleware ini memastikan identitas
 * user diverifikasi secara kriptografis di server (via tanda tangan Clerk),
 * bukan sekadar diklaim oleh client. Hasilnya dipakai OrderHash & cek kepemilikan.
 *
 * Verifikasi dilakukan tanpa package eksternal: ambil public key dari JWKS Clerk,
 * lalu verifikasi signature RS256 memakai OpenSSL bawaan PHP.
 */
class VerifyClerkToken
{
    public function handle(Request $request, Closure $next): Response
    {
        // Bungkus seluruh proses agar kegagalan auth SELALU jadi 401 bersih,
        // tidak pernah bocor jadi 500 (mis. saat fetch JWKS gagal koneksi).
        try {
            $token = $this->extractBearerToken($request);

            if (!$token) {
                return response()->json(['message' => 'Unauthorized'], 401);
            }

            $claims = $this->verifyJwt($token);

            if (!$claims || empty($claims['sub'])) {
                // Kode alasan bantu debugging tanpa membocorkan detail ke user.
                Log::warning('Clerk token ditolak', [
                    'ip'     => $request->ip(),
                    'reason' => $this->lastReason,
                ]);
                return response()->json([
                    'message' => 'Sesi Anda telah berakhir. Silakan muat ulang halaman.',
                ], 401);
            }

            $user = User::where('clerk_id', $claims['sub'])->first();

            // Lazy-sync: bila user lokal belum ada (mis. webhook user.created
            // pernah gagal), ambil datanya langsung dari Clerk API & buat di DB.
            // Ini membuat sistem tahan terhadap webhook yang terlewat.
            if (!$user) {
                $user = $this->syncUserFromClerk($claims['sub']);
            }

            if (!$user) {
                Log::warning('Clerk user belum tertaut & gagal lazy-sync', ['clerk_id' => $claims['sub']]);
                return response()->json([
                    'message' => 'Akun belum tersinkron. Silakan muat ulang halaman.',
                ], 401);
            }

            $request->setUserResolver(fn () => $user);
            return $next($request);
        } catch (\Throwable $e) {
            Log::error('VerifyClerkToken gagal', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'Unauthorized'], 401);
        }
    }

    /**
     * Ambil data user dari Clerk Backend API berdasarkan clerk_id, lalu buat
     * (atau perbarui) record User lokal. Dipakai sebagai fallback bila webhook
     * user.created tidak pernah berhasil membuat user ini.
     */
    private function syncUserFromClerk(string $clerkId): ?User
    {
        try {
            $secret = config('services.clerk.secret_key');
            if (empty($secret)) {
                $this->lastReason = 'CLERK_SECRET_KEY tidak diset';
                return null;
            }

            $resp = Http::withToken($secret)
                ->timeout(10)
                ->get("https://api.clerk.com/v1/users/{$clerkId}");

            if (!$resp->ok()) {
                Log::error('Gagal fetch user dari Clerk API', [
                    'clerk_id' => $clerkId,
                    'status'   => $resp->status(),
                ]);
                return null;
            }

            $data  = $resp->json();
            $email = $data['email_addresses'][0]['email_address'] ?? null;
            if (!$email) return null;

            $first = $data['first_name'] ?? '';
            $last  = $data['last_name'] ?? '';
            $name  = trim($first . ' ' . $last) ?: 'Pengguna';

            $userRole = Role::where('slug', 'user')->first();

            $user = User::updateOrCreate(
                ['clerk_id' => $clerkId],
                [
                    'role_id' => $userRole?->id,
                    'name'    => $name,
                    'email'   => $email,
                    'avatar'  => $data['image_url'] ?? null,
                ]
            );

            Log::info('User berhasil di-lazy-sync dari Clerk', ['clerk_id' => $clerkId, 'email' => $email]);
            return $user;
        } catch (\Throwable $e) {
            Log::error('syncUserFromClerk gagal', ['clerk_id' => $clerkId, 'error' => $e->getMessage()]);
            return null;
        }
    }

    /** Alasan penolakan terakhir (untuk log, tidak dikirim ke user). */
    private string $lastReason = '';

    /** Ambil token dari header Authorization: Bearer <token>. */
    private function extractBearerToken(Request $request): ?string
    {
        $header = $request->header('Authorization', '');
        if (str_starts_with($header, 'Bearer ')) {
            return trim(substr($header, 7));
        }
        return null;
    }

    /**
     * Verifikasi JWT RS256 Clerk secara manual.
     * Return array claims kalau valid, null kalau tidak.
     */
    private function verifyJwt(string $jwt): ?array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            return null;
        }
        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;

        $header  = json_decode($this->b64UrlDecode($encodedHeader), true);
        $payload = json_decode($this->b64UrlDecode($encodedPayload), true);
        $signature = $this->b64UrlDecode($encodedSignature);

        if (!is_array($header) || !is_array($payload) || $signature === false) {
            $this->lastReason = 'format token tidak valid';
            return null;
        }

        // Pastikan algoritma RS256 — cegah "alg: none" downgrade attack.
        if (($header['alg'] ?? '') !== 'RS256' || empty($header['kid'])) {
            $this->lastReason = 'algoritma/kid tidak valid';
            return null;
        }

        // Cek expiry (exp) & not-before (nbf). Leeway 60 detik untuk mentolerir
        // clock skew antara server & Clerk (token dev Clerk berumur pendek ~60s).
        $now    = time();
        $leeway = 60;
        if (isset($payload['exp']) && $now >= ($payload['exp'] + $leeway)) {
            $this->lastReason = 'token kadaluarsa';
            return null;
        }
        if (isset($payload['nbf']) && $now < ($payload['nbf'] - $leeway)) {
            $this->lastReason = 'token belum berlaku (nbf)';
            return null;
        }

        // Ambil public key (PEM) sesuai kid dari JWKS Clerk.
        $publicKey = $this->getPublicKeyForKid($header['kid']);
        if (!$publicKey) {
            $this->lastReason = 'public key JWKS tidak ditemukan';
            return null;
        }

        // Verifikasi signature: data yang ditandatangani = header.payload
        $signedData = $encodedHeader . '.' . $encodedPayload;
        $ok = openssl_verify($signedData, $signature, $publicKey, OPENSSL_ALGO_SHA256);

        if ($ok !== 1) {
            $this->lastReason = 'signature tidak cocok';
            return null;
        }
        return $payload;
    }

    /**
     * Ambil public key PEM dari JWKS Clerk berdasarkan `kid`.
     * JWKS di-cache 1 jam agar tidak fetch tiap request (dan tahan bila
     * endpoint Clerk sesekali lambat). Key rotation tetap ter-handle karena
     * cache berumur pendek.
     */
    private function getPublicKeyForKid(string $kid): ?string
    {
        $jwksUrl = config('services.clerk.jwks_url');
        if (empty($jwksUrl)) {
            Log::error('CLERK_JWKS_URL belum dikonfigurasi');
            return null;
        }

        $jwks = Cache::remember('clerk_jwks', now()->addHour(), function () use ($jwksUrl) {
            $resp = Http::timeout(10)->get($jwksUrl);
            return $resp->ok() ? $resp->json() : null;
        });

        if (!is_array($jwks) || empty($jwks['keys'])) {
            return null;
        }

        foreach ($jwks['keys'] as $key) {
            if (($key['kid'] ?? null) === $kid) {
                return $this->jwkToPem($key);
            }
        }

        return null;
    }

    /** Konversi JWK (n, e) → public key PEM yang bisa dipakai OpenSSL. */
    private function jwkToPem(array $jwk): ?string
    {
        if (empty($jwk['n']) || empty($jwk['e'])) {
            return null;
        }

        $modulus  = $this->b64UrlDecode($jwk['n']);
        $exponent = $this->b64UrlDecode($jwk['e']);

        // Bangun struktur ASN.1 DER untuk RSA public key.
        $modulus  = "\x00" . $modulus; // pastikan integer positif
        $modulusEnc  = $this->encodeAsn1Integer($modulus);
        $exponentEnc = $this->encodeAsn1Integer($exponent);

        $rsaPublicKey = $this->encodeAsn1Sequence($modulusEnc . $exponentEnc);

        // AlgorithmIdentifier untuk rsaEncryption (OID 1.2.840.113549.1.1.1)
        $rsaOid = "\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01\x05\x00";
        $bitString = $this->encodeAsn1BitString("\x00" . $rsaPublicKey);

        $der = $this->encodeAsn1Sequence($rsaOid . $bitString);

        $pem = "-----BEGIN PUBLIC KEY-----\n"
            . chunk_split(base64_encode($der), 64, "\n")
            . "-----END PUBLIC KEY-----\n";

        return $pem;
    }

    // ── Helper ASN.1 encoding ──────────────────────────────────────
    private function encodeAsn1Integer(string $bytes): string
    {
        return "\x02" . $this->encodeAsn1Length(strlen($bytes)) . $bytes;
    }

    private function encodeAsn1BitString(string $bytes): string
    {
        return "\x03" . $this->encodeAsn1Length(strlen($bytes)) . $bytes;
    }

    private function encodeAsn1Sequence(string $bytes): string
    {
        return "\x30" . $this->encodeAsn1Length(strlen($bytes)) . $bytes;
    }

    private function encodeAsn1Length(int $length): string
    {
        if ($length < 128) {
            return chr($length);
        }
        $bytes = '';
        while ($length > 0) {
            $bytes = chr($length & 0xff) . $bytes;
            $length >>= 8;
        }
        return chr(0x80 | strlen($bytes)) . $bytes;
    }

    private function b64UrlDecode(string $data): string
    {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        return base64_decode(strtr($data, '-_', '+/'));
    }
}
