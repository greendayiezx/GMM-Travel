<?php

namespace App\Services;

use Exception;

class MidtransService
{
    public function __construct()
    {
        \Midtrans\Config::$serverKey    = config('midtrans.server_key');
        \Midtrans\Config::$clientKey    = config('midtrans.client_key');
        \Midtrans\Config::$isProduction = config('midtrans.is_production');
        \Midtrans\Config::$isSanitized  = config('midtrans.is_sanitized');
        \Midtrans\Config::$is3ds        = config('midtrans.is_3ds');
    }

    /**
     * Generate Snap token untuk popup pembayaran (package tour, dll).
     * Frontend memanggil window.snap.pay(token) dengan token ini.
     */
    public function getSnapToken(
        string $orderId,
        int    $amount,
        string $customerName,
        ?string $customerEmail,
        string $itemName = 'Paket Wisata',
        array  $enabledPayments = []
    ): string {
        $params = [
            'transaction_details' => [
                'order_id'     => $orderId,
                'gross_amount' => $amount,
            ],
            'customer_details' => array_filter([
                'first_name' => $customerName,
                'email'      => $customerEmail ?: null,
            ]),
            'item_details' => [[
                'id'       => 'PKG-' . $orderId,
                'price'    => $amount,
                'quantity' => 1,
                'name'     => $itemName,
            ]],
        ];

        if (!empty($enabledPayments)) {
            $params['enabled_payments'] = $enabledPayments;
        }

        $snap = \Midtrans\Snap::getSnapToken($params);
        return $snap;
    }

    /**
     * Charge via Midtrans Core API.
     * Mengembalikan instruksi pembayaran (VA number, bill key, atau QR string)
     * langsung dari Midtrans — TANPA Snap popup.
     *
     * @param string $paymentMethod  'bni'|'bri'|'mandiri'|'gopay'|'ovo'|'dana'|'qris'
     */
    public function charge(
        string $invoiceNumber,
        float  $amount,
        string $paymentMethod,
        array  $customer,
        array  $item
    ): array {
        // PENTING (Midtrans): gross_amount WAJIB sama dengan total item_details
        // (harga × qty). Sebelumnya baris ADMIN_FEE terpisah membuat totalnya
        // tidak cocok (gross ≠ item+fee) → di production Midtrans MENOLAK.
        // Solusi: pakai SATU baris item yang harganya = gross_amount. Admin fee
        // sudah termasuk di `$amount` untuk flow travel/flight (total_amount),
        // sehingga nominal yang di-charge selalu konsisten dengan yang ditagih.
        $grossAmount = (int) $amount;

        $base = [
            'transaction_details' => [
                'order_id'     => $invoiceNumber,
                'gross_amount' => $grossAmount,
            ],
            'item_details' => [
                [
                    'id'       => $item['id'] ?? 'ITEM',
                    'price'    => $grossAmount,
                    'quantity' => 1,
                    'name'     => mb_substr((string) ($item['name'] ?? 'Pembayaran GMM Travel'), 0, 50),
                ],
            ],
            'customer_details' => [
                'first_name' => $customer['name'],
                'phone'      => $customer['phone'],
            ],
        ];

        $method = strtolower($paymentMethod);

        // Sandbox: Core API channel butuh aktivasi oleh Midtrans (tidak bisa lewat dashboard).
        // Gunakan data simulasi agar UI flow bisa ditest sepenuhnya.
        if (!config('midtrans.is_production')) {
            return $this->simulateSandbox($method, $invoiceNumber);
        }

        try {
            if (in_array($method, ['bca', 'bni', 'bri', 'permata', 'bsi', 'other'])) {
                $bank = $method === 'bsi' ? 'bni' : $method; // BSI pakai BNI VA di Core API
                $params = array_merge($base, [
                    'payment_type'  => 'bank_transfer',
                    'bank_transfer' => ['bank' => $bank],
                ]);
                $response = \Midtrans\CoreApi::charge($params);
                return $this->parseVaResponse($response);

            } elseif ($method === 'mandiri') {
                $params = array_merge($base, [
                    'payment_type' => 'echannel',
                    'echannel'     => [
                        'bill_info1' => 'GMM Travel',
                        'bill_info2' => $invoiceNumber,
                    ],
                ]);
                $response = \Midtrans\CoreApi::charge($params);
                return $this->parseMandiriResponse($response);

            } elseif ($method === 'gopay') {
                $params = array_merge($base, [
                    'payment_type' => 'gopay',
                    'gopay'        => ['enable_callback' => false],
                ]);
                $response = \Midtrans\CoreApi::charge($params);
                return $this->parseQrResponse($response);

            } else {
                // OVO, DANA, QRIS → semua pakai QRIS di Core API
                $params = array_merge($base, [
                    'payment_type' => 'qris',
                    'qris'         => ['acquirer' => 'gopay'],
                ]);
                $response = \Midtrans\CoreApi::charge($params);
                return $this->parseQrResponse($response);
            }
        } catch (Exception $e) {
            throw new Exception('Midtrans Core API Error: ' . $e->getMessage());
        }
    }

    private function simulateSandbox(string $method, string $invoiceNumber): array
    {
        if (in_array($method, ['bca', 'bni', 'bri', 'permata', 'bsi', 'other'])) {
            $prefixes = ['bca' => '70012', 'bni' => '8277', 'bri' => '26215', 'permata' => '8625', 'bsi' => '9347', 'other' => '8000'];
            $vaNumber = ($prefixes[$method] ?? '8000') . rand(1000000000, 9999999999);
            return [
                'transaction_id' => 'sandbox-' . \Illuminate\Support\Str::uuid(),
                'payment_type'   => 'va',
                'instructions'   => [
                    'va_number' => $vaNumber,
                    'bank'      => $method,
                ],
                'expired_at' => now()->addMinutes(15),
                'sandbox'    => true,
            ];
        }

        if ($method === 'mandiri') {
            return [
                'transaction_id' => 'sandbox-' . \Illuminate\Support\Str::uuid(),
                'payment_type'   => 'echannel',
                'instructions'   => [
                    'biller_code' => '70012',
                    'bill_key'    => (string) rand(1000000000000, 9999999999999),
                ],
                'expired_at' => now()->addMinutes(15),
                'sandbox'    => true,
            ];
        }

        // GoPay, OVO, DANA, QRIS → QR simulasi
        $qrString = 'https://sandbox.midtrans.com/qr/' . $invoiceNumber . '-' . rand(1000, 9999);
        return [
            'transaction_id' => 'sandbox-' . \Illuminate\Support\Str::uuid(),
            'payment_type'   => 'qr',
            'instructions'   => [
                'qr_string' => $qrString,
                'qr_code'   => $qrString,
            ],
            'expired_at' => now()->addMinutes(15),
            'sandbox'    => true,
        ];
    }

    private function parseVaResponse($response): array
    {
        $vaNumbers = $response->va_numbers ?? [];
        return [
            'transaction_id' => $response->transaction_id ?? null,
            'payment_type'   => 'va',
            'instructions'   => [
                'va_number' => $vaNumbers[0]->va_number ?? null,
                'bank'      => $vaNumbers[0]->bank ?? null,
            ],
            'expired_at' => now()->addMinutes(15),
        ];
    }

    private function parseMandiriResponse($response): array
    {
        return [
            'transaction_id' => $response->transaction_id ?? null,
            'payment_type'   => 'echannel',
            'instructions'   => [
                'bill_key'    => $response->bill_key ?? null,
                'biller_code' => $response->biller_code ?? null,
            ],
            'expired_at' => now()->addMinutes(15),
        ];
    }

    private function parseQrResponse($response): array
    {
        $actions  = $response->actions ?? [];
        $qrCode   = null;
        $deeplink = null;

        foreach ($actions as $action) {
            if (($action->name ?? '') === 'generate-qr-code') {
                $qrCode = $action->url;
            }
            if (($action->name ?? '') === 'deeplink-redirect') {
                $deeplink = $action->url;
            }
        }

        return [
            'transaction_id' => $response->transaction_id ?? null,
            'payment_type'   => 'qr',
            'instructions'   => [
                'qr_string' => $response->qr_string ?? $qrCode,
                'qr_code'   => $qrCode,
                'deeplink'  => $deeplink,
            ],
            'expired_at' => now()->addMinutes(15),
        ];
    }
}
