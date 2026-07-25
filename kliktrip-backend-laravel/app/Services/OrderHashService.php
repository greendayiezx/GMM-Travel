<?php

namespace App\Services;

use InvalidArgumentException;

/**
 * OrderHashService
 * ----------------
 * Menghasilkan & memverifikasi "order hash" yang dipakai di URL halaman sensitif
 * (payment, detail order, invoice) — mirip pola tiket.com.
 *
 * Tujuan keamanan: mencegah IDOR (Insecure Direct Object Reference).
 * Tanpa hash ini, attacker cukup mengganti angka order_id di URL untuk membaca
 * order milik user lain. Dengan hash yang terikat ke (order_id + user_id) dan
 * ditandatangani secret server, attacker tidak bisa menebak/memalsukan hash.
 */
class OrderHashService
{
    /** Panjang hash final yang diekspos ke URL (24 char, uppercase). */
    private const HASH_LENGTH = 24;

    /**
     * Ambil secret dari .env (ORDER_HASH_SECRET).
     * Secret TIDAK boleh di-hardcode — kalau bocor, semua hash bisa dipalsukan.
     */
    private function secret(): string
    {
        $secret = config('services.order_hash.secret');

        // Fail-fast di server: kalau secret belum diset, jangan diam-diam pakai
        // string kosong (itu membuat hash bisa ditebak).
        if (empty($secret)) {
            throw new InvalidArgumentException('ORDER_HASH_SECRET belum dikonfigurasi di .env');
        }

        return $secret;
    }

    /**
     * Susun payload yang ditandatangani.
     * Menggabungkan order_id + user_id → hash hanya valid untuk pasangan tsb,
     * sehingga user A tidak bisa memakai hash-nya untuk mengakses order user B.
     */
    private function payload(string $orderId, string $userId): string
    {
        return $orderId . '|' . $userId;
    }

    /**
     * Generate order hash: HMAC-SHA256 → uppercase → dipotong 24 karakter.
     */
    public function generate(string $orderId, string $userId): string
    {
        // HMAC-SHA256 dengan secret server. Output hex 64 char.
        $raw = hash_hmac('sha256', $this->payload($orderId, $userId), $this->secret());

        // Uppercase + potong 24 char sesuai spesifikasi URL yang diinginkan.
        return strtoupper(substr($raw, 0, self::HASH_LENGTH));
    }

    /**
     * Verifikasi hash yang datang dari URL.
     *
     * Memakai hash_equals() (constant-time comparison) untuk mencegah timing
     * attack — attacker tidak bisa menebak hash byte-per-byte dari selisih waktu.
     */
    public function verify(string $orderId, string $userId, string $providedHash): bool
    {
        $expected = $this->generate($orderId, $userId);

        // Normalisasi input attacker ke uppercase agar perbandingan konsisten.
        $provided = strtoupper(trim($providedHash));

        return hash_equals($expected, $provided);
    }
}
