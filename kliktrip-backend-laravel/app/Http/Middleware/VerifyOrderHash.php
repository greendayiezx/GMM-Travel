<?php

namespace App\Http\Middleware;

use App\Services\OrderHashService;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * VerifyOrderHash
 * ---------------
 * Melindungi halaman sensitif (payment, detail order, invoice) dari IDOR.
 *
 * Alur:
 *  1. Baca order_id & order_hash dari query string URL.
 *  2. Hitung ulang hash yang seharusnya dari (order_id + user_id user login).
 *  3. Bandingkan dengan hash_equals() (anti timing attack).
 *  4. Verifikasi lewat DB bahwa order tsb memang milik user yang login.
 *  5. Kalau salah satu gagal → 403 generik + dicatat ke log.
 *
 * Middleware ini WAJIB berjalan setelah VerifyClerkToken, karena butuh
 * $request->user() yang identitasnya sudah diverifikasi server.
 */
class VerifyOrderHash
{
    public function __construct(private OrderHashService $orderHash) {}

    public function handle(Request $request, Closure $next): Response
    {
        $user    = $request->user();
        $orderId = (string) $request->query('order_id', '');
        $hash    = (string) $request->query('order_hash', '');

        // Semua kondisi kegagalan memakai satu response generik yang sama —
        // jangan beri tahu attacker BAGIAN MANA yang gagal (order_id? hash?
        // kepemilikan?). Detail hanya masuk ke log server.
        $deny = fn (string $reason) => $this->reject($request, $orderId, $reason);

        if (!$user) {
            return $deny('user tidak terautentikasi');
        }
        if ($orderId === '' || $hash === '') {
            return $deny('order_id / order_hash kosong');
        }

        // (2)+(3) Verifikasi tanda tangan hash terhadap user yang sedang login.
        if (!$this->orderHash->verify($orderId, (string) $user->id, $hash)) {
            return $deny('hash tidak cocok');
        }

        // (4) Verifikasi kepemilikan di DB — pertahanan berlapis:
        // meski hash valid, pastikan order benar-benar ada & milik user ini.
        $order = $this->resolveOrder($orderId);
        if (!$order || (string) $order->user_id !== (string) $user->id) {
            return $deny('order bukan milik user / tidak ditemukan');
        }

        // Sisipkan order yang sudah tervalidasi agar controller tidak perlu
        // query ulang (dan tidak tergoda memakai order_id mentah dari URL).
        $request->attributes->set('verified_order', $order);

        return $next($request);
    }

    /**
     * Ambil order dari DB memakai Eloquent (parameter binding otomatis,
     * aman dari SQL injection).
     *
     * Order di sistem ini polimorfik (FlightBooking / TravelBooking / TourBooking).
     * Untuk contoh ini kita resolusi lewat FlightBooking; sesuaikan bila perlu
     * mendukung tipe order lain.
     */
    private function resolveOrder(string $orderId): mixed
    {
        // UUID unik lintas tabel → cek tiap tipe order. Semua punya kolom user_id.
        return \App\Models\PackageOrder::find($orderId)
            ?? \App\Models\FlightBooking::find($orderId)
            ?? \App\Models\TravelBooking::find($orderId);
    }

    /**
     * Tolak akses dengan 403 + pesan generik, dan catat percobaan ke log.
     * Logging berisi konteks untuk investigasi (IP, user, order_id, alasan),
     * tapi TIDAK dikirim ke user.
     */
    private function reject(Request $request, string $orderId, string $reason): Response
    {
        Log::warning('Percobaan akses order ditolak (kemungkinan IDOR)', [
            'reason'   => $reason,
            'ip'       => $request->ip(),
            'user_id'  => optional($request->user())->id,
            'order_id' => $orderId,
            'path'     => $request->path(),
            'agent'    => $request->userAgent(),
        ]);

        return response()->json(['message' => 'Akses ditolak.'], 403);
    }
}
