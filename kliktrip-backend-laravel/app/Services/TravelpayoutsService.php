<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Wrapper untuk Travelpayouts prices_for_dates API.
 * Digunakan sebagai FALLBACK ketika Duffel tidak mengembalikan hasil.
 *
 * Tiket yang dihasilkan tidak bookable langsung — user diarahkan ke partner
 * link (redirect_link). Validasi/filter data tetap dilakukan di
 * FlightSearchController::filterAndValidateFlights() supaya konsisten.
 */
class TravelpayoutsService
{
    private string $token;
    private string $marker;
    private int    $timeout;

    public function __construct()
    {
        $cfg = config('services.travelpayouts');
        $this->token   = $cfg['token']   ?? '';
        $this->marker  = $cfg['marker']  ?? '';
        $this->timeout = $cfg['timeout'] ?? 15;
    }

    /**
     * Cari penawaran ke Travelpayouts (3 tanggal: H-1, H, H+1) lalu dedupe.
     *
     * @return array Raw items dari Travelpayouts (belum di-normalize).
     */
    public function searchRaw(string $origin, string $destination, string $departureDate): array
    {
        if ($this->token === '') return [];

        // Fetch H-3 sampai H+3 untuk lebih banyak pilihan tiket
        $dates = [];
        for ($i = -3; $i <= 3; $i++) {
            $dates[] = date('Y-m-d', strtotime($departureDate . " {$i} day"));
        }
        $all = [];
        foreach ($dates as $d) {
            try {
                $resp = Http::timeout($this->timeout)->get(
                    'https://api.travelpayouts.com/aviasales/v3/prices_for_dates',
                    [
                        'origin'       => strtoupper($origin),
                        'destination'  => strtoupper($destination),
                        'departure_at' => $d,
                        'currency'     => 'idr',
                        'locale'       => 'id',
                        'limit'        => 20,
                        'sorting'      => 'price',
                        'token'        => $this->token,
                    ]
                );
                if ($resp->successful()) {
                    $all = array_merge($all, $resp->json('data', []));
                }
            } catch (Throwable $e) {
                Log::warning('TravelpayoutsService: request gagal tanggal ' . $d . ': ' . $e->getMessage());
            }
        }
        return $all;
    }

    /**
     * Ambil harga termurah per-tanggal untuk satu bulan (calendar view).
     * Travelpayouts v2/prices/calendar mengembalikan map tanggal→harga.
     *
     * @return array<string, int>  key = 'YYYY-MM-DD', value = harga IDR termurah
     */
    public function calendarPrices(string $origin, string $destination, string $yearMonth): array
    {
        if ($this->token === '') return [];

        try {
            $resp = Http::timeout($this->timeout)->get(
                'https://api.travelpayouts.com/v2/prices/calendar',
                [
                    'origin'       => strtoupper($origin),
                    'destination'  => strtoupper($destination),
                    'depart_date'  => $yearMonth,   // format: '2026-07'
                    'currency'     => 'idr',
                    'token'        => $this->token,
                ]
            );

            if (!$resp->successful()) return [];

            $raw = $resp->json('data', []);
            // Struktur: { "ORIGIN": { "DESTINATION": { "YYYY-MM-DD": { price, ... } } } }
            $byDate = data_get($raw, strtoupper($origin) . '.' . strtoupper($destination), []);

            $result = [];
            foreach ($byDate as $date => $info) {
                $price = (int) ($info['price'] ?? 0);
                if ($price > 0) {
                    $result[$date] = $price;
                }
            }
            return $result;
        } catch (Throwable $e) {
            Log::warning('TravelpayoutsService: calendarPrices gagal: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Bangun partner redirect link untuk booking di Aviasales.
     */
    public function buildRedirectLink(
        string $origin,
        string $destination,
        string $departureDate,
        int    $adults = 1
    ): string {
        // Format: https://www.aviasales.com/search/{ORIGIN}{DDMM}{DESTINATION}{RETURNDDMM}{ADULTS}
        $depFmt = date('dm', strtotime($departureDate));
        $suffix = $this->marker ? '?marker=' . $this->marker : '';
        return "https://www.aviasales.com/search/{$origin}{$depFmt}{$destination}{$adults}" . $suffix;
    }
}
