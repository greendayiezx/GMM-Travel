<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Wrapper untuk Duffel Air API (offer_requests).
 * Bertugas melakukan pencarian penawaran tiket dan me-normalisasi respons
 * menjadi format standar {source, bookable, offers[]} yang dipakai frontend.
 *
 * Semua panggilan Duffel WAJIB melalui service ini — jangan panggil langsung
 * dari controller supaya token tidak bocor & error handling terpusat.
 */
class DuffelService
{
    private string $token;
    private string $version;
    private string $base;
    private int    $timeout;

    public function __construct()
    {
        $cfg = config('services.duffel');
        $this->token   = $cfg['token']   ?? '';
        $this->version = $cfg['version'] ?? 'v2';
        $this->base    = $cfg['base']    ?? 'https://api.duffel.com';
        $this->timeout = $cfg['timeout'] ?? 15;
    }

    /**
     * Cari penawaran penerbangan via Duffel.
     *
     * @return array Normalized offers dalam format {id, price, currency, airline,
     *               flightNumber, origin, destination, departureTime, arrivalTime,
     *               duration, transitCount, departure_at, bookable, redirect_link?, raw}
     *               atau [] jika gagal / tidak ada hasil.
     */
    public function searchOffers(
        string $origin,
        string $destination,
        string $departureDate,
        int    $adults    = 1,
        int    $children  = 0,
        int    $infants   = 0,
        string $cabinClass = 'economy'
    ): array {
        if ($this->token === '') {
            Log::warning('DuffelService: token kosong, skip');
            return [];
        }

        $passengers = [];
        for ($i = 0; $i < $adults;   $i++) $passengers[] = ['type' => 'adult'];
        for ($i = 0; $i < $children; $i++) $passengers[] = ['type' => 'child'];
        for ($i = 0; $i < $infants;  $i++) $passengers[] = ['type' => 'infant_without_seat'];

        $body = [
            'data' => [
                'slices' => [[
                    'origin'         => strtoupper($origin),
                    'destination'    => strtoupper($destination),
                    'departure_date' => $departureDate,
                ]],
                'passengers'  => $passengers,
                'cabin_class' => $cabinClass,
            ],
        ];

        try {
            $response = Http::withHeaders([
                'Authorization'  => 'Bearer ' . $this->token,
                'Duffel-Version' => $this->version,
                'Accept'         => 'application/json',
                'Content-Type'   => 'application/json',
            ])
                ->timeout($this->timeout)
                ->post($this->base . '/air/offer_requests?return_offers=true', $body);

            if (!$response->successful()) {
                Log::warning('DuffelService: request failed', [
                    'status' => $response->status(),
                    'body'   => substr($response->body(), 0, 500),
                ]);
                return [];
            }

            $offers = data_get($response->json(), 'data.offers', []);
            if (empty($offers)) return [];

            return $this->normalize($offers, $origin, $destination);
        } catch (Throwable $e) {
            Log::error('DuffelService exception: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Kurs perkiraan mata uang → IDR untuk normalisasi harga.
     * Duffel Air API mengembalikan harga dalam currency asli maskapai
     * (biasanya USD/EUR/GBP untuk long-haul). Karena frontend selalu
     * menampilkan "Rp X", harga dikonversi di sini.
     */
    private array $rateToIdr = [
        'IDR' => 1,
        'USD' => 16000,
        'EUR' => 17500,
        'GBP' => 20500,
        'SGD' => 12000,
        'MYR' => 3700,
        'AUD' => 10500,
        'JPY' => 105,
        'HKD' => 2050,
        'THB' => 460,
        'CNY' => 2250,
        'KRW' => 12,
        'AED' => 4350,
        'SAR' => 4260,
        'QAR' => 4390,
        'TRY' => 500,
    ];

    private function convertToIdr(float $amount, string $currency): int
    {
        $rate = $this->rateToIdr[strtoupper($currency)] ?? 16000; // fallback USD
        return (int) round($amount * $rate);
    }

    /**
     * Ambil harga TERKINI sebuah offer Duffel (re-pricing) untuk verifikasi
     * server-side sebelum charge — mencegah manipulasi harga dari client.
     *
     * @return int|null  Harga total offer dalam IDR, atau null jika offer sudah
     *                   kadaluarsa / tidak tersedia / error.
     */
    public function getOfferPriceIdr(string $offerId): ?int
    {
        if ($this->token === '' || $offerId === '') {
            return null;
        }

        try {
            $response = Http::withHeaders([
                'Authorization'  => 'Bearer ' . $this->token,
                'Duffel-Version' => $this->version,
                'Accept'         => 'application/json',
            ])
                ->timeout($this->timeout)
                ->get($this->base . '/air/offers/' . $offerId);

            // 404/410 → offer sudah kadaluarsa. Bukan error tak terduga.
            if (!$response->successful()) {
                Log::info('Duffel offer tidak tersedia (mungkin kadaluarsa)', [
                    'offer_id' => $offerId,
                    'status'   => $response->status(),
                ]);
                return null;
            }

            $amount   = (float) data_get($response->json(), 'data.total_amount', 0);
            $currency = strtoupper((string) data_get($response->json(), 'data.total_currency', 'USD'));
            if ($amount <= 0) {
                return null;
            }

            return $this->convertToIdr($amount, $currency);
        } catch (\Throwable $e) {
            Log::warning('Duffel getOfferPriceIdr gagal', ['offer_id' => $offerId, 'error' => $e->getMessage()]);
            return null;
        }
    }

    /** Maskapai yang dikenali — buang kode aneh seperti ZZ, XX, dsb dari Duffel */
    private array $knownAirlines = [
        'GA','QG','JT','ID','IU','IN','SJ','IL','BI','8B','IW','KD','GI','MV',
        'SQ','MI','TZ','TR','MH','OD','AK','QZ','D7','XT','TG','PG','VN','PR','UL',
        'CX','KE','OZ','JL','NH','BR','CI','CA','CZ','MU',
        'EK','QR','EY','SV','GF','TK','SV',
        'LH','KL','AF','BA','QF','EY',
    ];

    /**
     * Normalisasi offers Duffel ke format seragam yang dipakai frontend.
     */
    private function normalize(array $offers, string $origin, string $destination): array
    {
        $result = [];
        foreach ($offers as $offer) {
            $firstSlice   = data_get($offer, 'slices.0');
            $segments     = data_get($firstSlice, 'segments', []);
            $firstSegment = $segments[0]  ?? null;
            $lastSegment  = $segments[count($segments) - 1] ?? null;
            if (!$firstSegment || !$lastSegment) continue;

            // Filter out layover extreme > 12 jam (bermalam / hampir sehari penuh)
            $skipOffer = false;
            for ($i = 0; $i < count($segments) - 1; $i++) {
                $arr = data_get($segments[$i],   'arriving_at');
                $dep = data_get($segments[$i+1], 'departing_at');
                if (!$arr || !$dep) continue;
                $layoverMin = (strtotime($dep) - strtotime($arr)) / 60;
                if ($layoverMin > 720) { // > 12 jam
                    $skipOffer = true;
                    break;
                }
            }
            if ($skipOffer) continue;

            $depAt = data_get($firstSegment, 'departing_at');
            $arrAt = data_get($lastSegment,  'arriving_at');

            $durationIso = data_get($firstSlice, 'duration'); // ISO 8601 e.g. "PT2H30M"
            $durationMin = $this->parseIsoDuration($durationIso);

            $airlineCode = strtoupper((string) data_get($offer, 'owner.iata_code',
                               data_get($firstSegment, 'operating_carrier.iata_code', '')));
            $flightNum   = data_get($firstSegment, 'operating_carrier_flight_number',
                               data_get($firstSegment, 'marketing_carrier_flight_number', ''));

            // Buang maskapai tidak dikenali (ZZ, XX, dsb)
            if (!in_array($airlineCode, $this->knownAirlines, true)) continue;

            $originalCurrency = strtoupper((string) data_get($offer, 'total_currency', 'USD'));
            $originalAmount   = (float) data_get($offer, 'total_amount', 0);
            $priceIdr         = $this->convertToIdr($originalAmount, $originalCurrency);

            // Segmen detail untuk timeline transit yang akurat (bukan hub tebak)
            $segmentDetails = array_map(fn($seg) => [
                'origin'         => strtoupper(data_get($seg, 'origin.iata_code', '')),
                'destination'    => strtoupper(data_get($seg, 'destination.iata_code', '')),
                'departing_at'   => data_get($seg, 'departing_at'),
                'arriving_at'    => data_get($seg, 'arriving_at'),
                'flight_number'  => data_get($seg, 'operating_carrier_flight_number',
                                       data_get($seg, 'marketing_carrier_flight_number', '')),
                'airline'        => strtoupper(data_get($seg, 'operating_carrier.iata_code',
                                       data_get($seg, 'marketing_carrier.iata_code', ''))),
            ], $segments);

            $result[] = [
                'id'            => data_get($offer, 'id', 'duf_' . uniqid()),
                'airline'       => strtoupper($airlineCode),
                'flightNumber'  => strtoupper($airlineCode) . $flightNum,
                'origin'        => strtoupper(data_get($firstSegment, 'origin.iata_code', $origin)),
                'destination'   => strtoupper(data_get($lastSegment, 'destination.iata_code', $destination)),
                'departureTime' => $depAt ? substr($depAt, 11, 5) : '',
                'arrivalTime'   => $arrAt ? substr($arrAt, 11, 5) : '',
                'duration'      => $this->formatDuration($durationMin),
                'transitCount'  => max(count($segments) - 1, 0),
                'price'         => $priceIdr,
                'currency'      => 'IDR',
                'originalPrice'    => $originalAmount,
                'originalCurrency' => $originalCurrency,
                'bookingClass'  => ucfirst(data_get($offer, 'cabin_class', 'economy')),
                'departure_at'  => $depAt,
                'bookable'      => true, // Duffel bisa langsung booking di web kita
                'segments'      => $segmentDetails, // ← untuk detail perjalanan akurat
                'raw'           => $offer,
            ];
        }
        return $result;
    }

    private function parseIsoDuration(?string $iso): int
    {
        if (!$iso) return 0;
        // Support penuh: P[nD]T[nH][nM]
        // Contoh: PT2H30M, PT45M, P1DT4H30M (layover panjang lebih dari 24 jam)
        if (!preg_match('/P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?/', $iso, $m)) return 0;
        $days  = (int) ($m[1] ?? 0);
        $hours = (int) ($m[2] ?? 0);
        $mins  = (int) ($m[3] ?? 0);
        return $days * 1440 + $hours * 60 + $mins;
    }

    private function formatDuration(int $minutes): string
    {
        if ($minutes <= 0) return '-';
        $h = intdiv($minutes, 60);
        $m = $minutes % 60;
        return $h > 0 ? "{$h}j {$m}m" : "{$m}m";
    }
}
