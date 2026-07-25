<?php

namespace App\Http\Controllers;

use App\Services\OrderHashService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

/**
 * OrderController
 * ---------------
 * Contoh controller untuk halaman sensitif (detail order, invoice, payment).
 *
 * Semua method di sini dilindungi middleware `clerk.auth` + `order.hash`,
 * sehingga:
 *  - Identitas user sudah diverifikasi (VerifyClerkToken).
 *  - Order sudah dipastikan milik user tsb & hash valid (VerifyOrderHash).
 * Controller tinggal memakai order yang sudah tervalidasi dari request.
 */
class OrderController extends Controller
{
    public function __construct(private OrderHashService $orderHash) {}

    /**
     * Endpoint untuk membuat URL bertanda tangan.
     * Frontend memanggil ini (dengan token Clerk) untuk mendapatkan order_hash,
     * lalu memakainya saat membuka halaman payment/detail/invoice.
     */
    public function signedUrl(Request $request, string $orderId): JsonResponse
    {
        $user = $request->user();

        // Hash dibuat dari order_id + user_id user yang login → tidak bisa
        // dipakai untuk order milik user lain.
        $hash = $this->orderHash->generate($orderId, (string) $user->id);

        return response()->json([
            'order_id'   => $orderId,
            'order_hash' => $hash,
        ]);
    }

    /** Detail order — hanya bisa diakses pemilik dengan hash valid. */
    public function show(Request $request): JsonResponse
    {
        // Order sudah divalidasi & disisipkan oleh middleware order.hash.
        $order = $request->attributes->get('verified_order');

        return response()->json(['data' => $order]);
    }

    /** Invoice order — proteksi sama seperti show(). */
    public function invoice(Request $request): JsonResponse
    {
        $order = $request->attributes->get('verified_order');

        return response()->json([
            'data' => [
                'order'   => $order,
                'invoice' => [
                    'number' => 'INV-' . $order->id,
                    'total'  => $order->total_amount,
                    'status' => $order->status,
                ],
            ],
        ]);
    }
}
