<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use App\Services\FlightSearchOrchestrator;
use App\Services\TravelpayoutsService;

class FlightSearchController extends Controller
{
    private string $apiToken;
    private FlightSearchOrchestrator $orchestrator;
    private TravelpayoutsService     $travelpayouts;

    /** Bandara domestik Indonesia (IATA) */
    private array $domesticAirports = [
        'CGK','HLP','SUB','DPS','UPG','MDC','KNO','BPN','PLM','JOG','SRG',
        'PNK','BDJ','BTH','BTJ','PDG','MES','DJJ','AMQ','KDI','PLW','LOP',
        'TIM','SOC','SRI','KOE','MOF','TKG','PGK','TJQ','GNS','BKS','MLG',
        'TRK','TTE','LUW','PLW','MKQ','BIK','FKQ','NBX','LBJ','WMX',
    ];

    /** Maskapai internasional-only — tidak boleh muncul di rute domestik penuh */
    private array $internationalOnlyAirlines = [
        'OD','MH','AK','D7','XT','SQ','MI','TR','TZ','CX','BR','CI',
        'JL','NH','BI','CZ','CA','MU','KE','OZ','TG','VN','PR','PG',
        'UL','EK','QR','EY','TK','KL','LH','AF',
    ];

    /** Maskapai domestik Indonesia — harus punya minimal 1 endpoint di Indonesia */
    private array $indonesianDomesticAirlines = [
        'JT','QG','IU','SJ','ID','IN','IL','8B','IW','GA','KD','GI','MV',
    ];

    /** Whitelist maskapai yang dikenali — apapun di luar ini di-filter (misal "ZZ") */
    private array $knownAirlines = [
        // Indonesia
        'GA','QG','JT','ID','IU','IN','SJ','IL','BI','8B','IW','KD','GI','MV',
        // ASEAN & Asia
        'SQ','MI','TZ','TR','MH','OD','AK','QZ','D7','XT','TG','PG','VN','PR','UL','MI',
        // Asia Timur
        'CX','KE','OZ','JL','NH','BR','CI','CA','CZ','MU',
        // Timur Tengah
        'EK','QR','EY','SV','GF','TK',
        // Eropa & lain-lain
        'LH','KL','AF','BA','QF',
    ];

    /** Koordinat bandara (lat, lon) untuk validasi jarak & kecepatan */
    private array $airportCoords = [
        // Indonesia
        'CGK' => [-6.1256, 106.6559], 'HLP' => [-6.2666, 106.8908],
        'DPS' => [-8.7482, 115.1671], 'SUB' => [-7.3798, 112.7869],
        'UPG' => [-5.0616, 119.5540], 'MDC' => [1.5495, 124.9256],
        'KNO' => [3.6422, 98.8853],   'BPN' => [-1.2683, 116.8944],
        'PLM' => [-2.8985, 104.6996], 'JOG' => [-7.9006, 110.0567],
        'SRG' => [-6.9727, 110.3750], 'PNK' => [-0.1508, 109.4039],
        'BDJ' => [-3.4425, 114.7625], 'BTH' => [1.1210, 104.1187],
        'PDG' => [-0.7869, 100.2809], 'DJJ' => [-2.5769, 140.5164],
        'AMQ' => [-3.7103, 128.0894], 'KDI' => [-4.0816, 122.4178],
        'PLW' => [-0.9185, 119.9100], 'LOP' => [-8.7573, 116.2761],
        // Asia Tenggara
        'SIN' => [1.3644, 103.9915],  'KUL' => [2.7456, 101.7099],
        'BKK' => [13.6900, 100.7501], 'DMK' => [13.9126, 100.6067],
        'MNL' => [14.5086, 121.0198], 'SGN' => [10.8188, 106.6519],
        'HAN' => [21.2187, 105.8047],
        // Asia Timur & Selatan
        'HKG' => [22.3080, 113.9185], 'NRT' => [35.7719, 140.3928],
        'HND' => [35.5494, 139.7798], 'ICN' => [37.4602, 126.4407],
        'PEK' => [40.0801, 116.5846], 'PVG' => [31.1443, 121.8083],
        'TPE' => [25.0797, 121.2342], 'DEL' => [28.5562, 77.1000],
        // Australia & lain-lain
        'SYD' => [-33.9399, 151.1753], 'MEL' => [-37.6690, 144.8410],
        'PER' => [-31.9385, 115.9672],
        // Amerika Utara
        'YHM' => [43.1735, -79.9350], 'YYZ' => [43.6777, -79.6248],
        'JFK' => [40.6413, -73.7781], 'LAX' => [33.9425, -118.4081],
        'SFO' => [37.6213, -122.3790],
        // Timur Tengah / Eropa
        'DXB' => [25.2532, 55.3657],  'DOH' => [25.2731, 51.6081],
        'IST' => [41.2753, 28.7519],  'LHR' => [51.4700, -0.4543],
        'CDG' => [49.0097, 2.5479],   'AMS' => [52.3105, 4.7683],
    ];

    /** Maksimum durasi wajar rute domestik langsung (menit) */
    private array $maxDomesticDuration = [
        'CGK-SUB' => 105, 'CGK-DPS' => 130, 'CGK-JOG' => 85,  'CGK-SRG' => 90,
        'CGK-UPG' => 175, 'CGK-KNO' => 150, 'CGK-BPN' => 165, 'CGK-MDC' => 200,
        'CGK-PLM' => 90,  'CGK-PNK' => 115, 'CGK-BDJ' => 150, 'CGK-BTH' => 110,
        'CGK-PDG' => 130, 'CGK-DJJ' => 320, 'CGK-AMQ' => 250,
        'SUB-DPS' => 75,  'SUB-UPG' => 110, 'SUB-JOG' => 70,  'SUB-BPN' => 125,
        'DPS-UPG' => 115, 'DPS-JOG' => 105, 'DPS-LOP' => 45,
        'UPG-MDC' => 100, 'UPG-KDI' => 80,  'UPG-BPN' => 90,
        'KNO-PDG' => 85,  'KNO-BTH' => 80,  'KNO-PLM' => 110,
    ];

    public function __construct(
        FlightSearchOrchestrator $orchestrator,
        TravelpayoutsService     $travelpayouts
    ) {
        $this->apiToken      = config('services.travelpayouts.token', '');
        $this->orchestrator  = $orchestrator;
        $this->travelpayouts = $travelpayouts;
    }

    /**
     * Bersihkan & validasi hasil Travelpayouts sebelum di-render.
     *
     * Aturan:
     *   1. Buang maskapai internasional-only jika rute origin+destination keduanya domestik.
     *   2. Buang tiket langsung (transfers=0) yang durasinya melebihi batas wajar rute.
     *   3. Buang tiket dengan durasi nol/negatif atau harga <= 0.
     *   4. Buang tiket yang durasinya terlalu panjang secara umum (> 24 jam untuk domestik).
     */
    private function filterAndValidateFlights(array $data, string $origin, string $destination): array
    {
        $isDomestic = in_array($origin, $this->domesticAirports, true)
                   && in_array($destination, $this->domesticAirports, true);

        return array_values(array_filter($data, function ($item) use ($origin, $destination, $isDomestic) {
            $airline   = strtoupper($item['airline'] ?? '');
            $duration  = (int) ($item['duration'] ?? $item['duration_to'] ?? 0);
            $transfers = (int) ($item['transfers'] ?? 0);
            $price     = (int) ($item['price'] ?? 0);

            // Rule 3 — data korup / kosong
            if ($duration <= 0 || $price <= 0) return false;

            // Rule 3b — maskapai tidak dikenali (misal "ZZ", "XX") — buang.
            // Menghindari tampilan "Penerbangan ZZ - Pesawat Komersial" yang confusing.
            if (!in_array($airline, $this->knownAirlines, true)) return false;

            // Rule 4 — durasi absurd (>24 jam untuk domestik, >30 jam untuk lain)
            $maxAbsolute = $isDomestic ? 24 * 60 : 30 * 60;
            if ($duration > $maxAbsolute) return false;

            // Rule 1 — maskapai internasional-only pada rute full-domestik
            if ($isDomestic && in_array($airline, $this->internationalOnlyAirlines, true)) {
                return false;
            }

            // Rule 2 — durasi rute domestik langsung melebihi batas wajar
            if ($isDomestic && $transfers === 0) {
                $key    = "{$origin}-{$destination}";
                $altKey = "{$destination}-{$origin}";
                $maxDur = $this->maxDomesticDuration[$key]
                       ?? $this->maxDomesticDuration[$altKey]
                       ?? 240; // fallback 4 jam
                // toleransi +30 menit untuk pembulatan API
                if ($duration > $maxDur + 30) return false;
            }

            // Rule 5 — Maskapai domestik Indonesia HARUS punya KEDUA endpoint di Indonesia.
            // Menggunakan gerbang AND: jika salah satu atau kedua bandara berada di luar
            // Indonesia, penerbangan otomatis dibuang.
            // Contoh yang di-blokir: Super Air Jet (IU) YHM (Kanada) → CGK,
            //                       Citilink (QG) SIN → KUL, dll.
            if (in_array($airline, $this->indonesianDomesticAirlines, true)) {
                $originIsID = $this->isIndonesianAirport($origin);
                $destIsID   = $this->isIndonesianAirport($destination);
                // WAJIB kedua endpoint di Indonesia
                if (!($originIsID && $destIsID)) {
                    return false;
                }
            }

            // Rule 7 — Buang tiket dengan transit > 2. Kombinasi 3+ transit dari
            // Travelpayouts sering merupakan hasil agregasi yang tidak realistis.
            if ($transfers > 2) return false;

            // Rule 6 — Validasi kecepatan wajar (haversine).
            // Pesawat komersial ~700-1000 km/h. Batas atas 1300 km/h (buang supersonik palsu).
            // Batas bawah dilonggarkan ke 250 km/h supaya penerbangan domestik dengan buffer
            // holding-pattern / delay tetap dianggap sah.
            $dist = $this->distanceKm($origin, $destination);
            if ($dist !== null && $duration > 0) {
                $hours = $duration / 60;
                $speed = $dist / max($hours, 0.1);
                // Kecepatan mustahil (data korup: durasi terlalu pendek untuk jaraknya)
                if ($speed > 1300) return false;
                // Kecepatan terlalu lambat untuk penerbangan langsung — ambang longgar
                if ($transfers === 0 && $speed < 250 && $dist > 300) return false;
            }

            return true;
        }));
    }

    /**
     * Cek apakah bandara berada di Indonesia.
     */
    private function isIndonesianAirport(string $code): bool
    {
        return in_array($code, $this->domesticAirports, true);
    }

    /**
     * Hitung jarak antar bandara dalam km via rumus Haversine.
     * Return null jika salah satu koordinat tidak dikenal.
     */
    private function distanceKm(string $a, string $b): ?float
    {
        $ca = $this->airportCoords[$a] ?? null;
        $cb = $this->airportCoords[$b] ?? null;
        if (!$ca || !$cb) return null;

        $lat1 = deg2rad($ca[0]);  $lon1 = deg2rad($ca[1]);
        $lat2 = deg2rad($cb[0]);  $lon2 = deg2rad($cb[1]);
        $dLat = $lat2 - $lat1;    $dLon = $lon2 - $lon1;

        $h = sin($dLat / 2) ** 2 + cos($lat1) * cos($lat2) * sin($dLon / 2) ** 2;
        return 2 * 6371 * asin(sqrt($h));
    }

    /**
     * Proxy pencarian harga tiket ke Travelpayouts API.
     * Menghindari ekspos API key ke frontend.
     */
    public function search(Request $request)
    {
        $request->validate([
            'origin'         => ['required', 'string', 'size:3'],
            'destination'    => ['required', 'string', 'size:3'],
            'departure_date' => ['required', 'date_format:Y-m-d'],
            'return_date'    => ['nullable', 'date_format:Y-m-d'],
            'adults'         => ['required', 'integer', 'min:1', 'max:9'],
            'children'       => ['nullable', 'integer', 'min:0', 'max:8'],
            'infants'        => ['nullable', 'integer', 'min:0', 'max:8'],
            'seat_class'     => ['nullable', 'string', 'in:Economy,Business,Premium Economy,First'],
        ]);

        $cacheKey = 'flight_search_' . md5(json_encode($request->all()));

        $payload = Cache::store('file')->remember($cacheKey, 300, function () use ($request) {
            $origin      = strtoupper($request->input('origin'));
            $destination = strtoupper($request->input('destination'));
            $date        = $request->input('departure_date');
            $adults      = (int) $request->input('adults', 1);
            $children    = (int) $request->input('children', 0);
            $infants     = (int) $request->input('infants', 0);
            $seatClass   = $request->input('seat_class', 'Economy');

            // Map UI seat class to Duffel cabin class string
            $cabinClass = 'economy';
            if ($seatClass === 'Business') {
                $cabinClass = 'business';
            } elseif ($seatClass === 'Premium Economy') {
                $cabinClass = 'premium_economy';
            } elseif ($seatClass === 'First') {
                $cabinClass = 'first';
            }

            // Price multiplier for non-Duffel providers
            $multiplier = 1.0;
            if ($seatClass === 'Premium Economy') {
                $multiplier = 1.5;
            } elseif ($seatClass === 'Business') {
                $multiplier = 2.5;
            } elseif ($seatClass === 'First') {
                $multiplier = 4.0;
            }

            // Orchestrator: Duffel dulu, lalu Travelpayouts fallback
            $result = $this->orchestrator->search(
                $origin, $destination, $date, $adults, $children, $infants, $cabinClass
            );

            // Kasus 1: Duffel berhasil → offers sudah dinormalisasi
            if ($result['source'] === 'duffel' && !empty($result['offers'])) {
                // Bangun date_prices dari TP untuk tanggal sekitar
                $tpDatePrices = [];
                try {
                    $tpService = app(\App\Services\TravelpayoutsService::class);
                    $tpRaw = $tpService->searchRaw($origin, $destination, $date);
                    foreach ($tpRaw as $item) {
                        $depAt = $item['departure_at'] ?? '';
                        $price = (int) ($item['price'] ?? 0);
                        if ($price <= 0 || empty($depAt)) continue;
                        $dateKey = substr($depAt, 0, 10);
                        $adjustedPrice = (int) round($price * $multiplier);
                        if (!isset($tpDatePrices[$dateKey]) || $adjustedPrice < $tpDatePrices[$dateKey]) {
                            $tpDatePrices[$dateKey] = $adjustedPrice;
                        }
                    }
                } catch (\Throwable $e) {}

                // Harga tanggal aktif dari Duffel offers (termurah)
                $cheapest = null;
                foreach ($result['offers'] as $offer) {
                    $p = (int) ($offer['price'] ?? 0);
                    if ($p > 0 && ($cheapest === null || $p < $cheapest)) {
                        $cheapest = $p;
                    }
                }
                if ($cheapest) {
                    $tpDatePrices[$date] = $cheapest;
                }

                return [
                    'source'      => 'duffel',
                    'bookable'    => true,
                    'data'        => $result['offers'],
                    'date_prices' => $tpDatePrices,
                ];
            }

            // Kasus 2: Fallback Travelpayouts — jalankan validator existing & normalize
            $rawAll = $result['raw'] ?? [];
            $allData = $this->filterAndValidateFlights($rawAll, $origin, $destination);

            // Bangun harga termurah per-tanggal dari SEMUA data yang valid
            $datePrices = [];
            foreach ($allData as $item) {
                $depAt = $item['departure_at'] ?? '';
                $price = (int) ($item['price'] ?? 0);
                if ($price <= 0 || empty($depAt)) continue;
                $dateKey = substr($depAt, 0, 10);
                $adjustedPrice = (int) round($price * $multiplier);
                if (!isset($datePrices[$dateKey]) || $adjustedPrice < $datePrices[$dateKey]) {
                    $datePrices[$dateKey] = $adjustedPrice;
                }
            }

            // Filter hanya flight untuk tanggal yang diminta
            $allData = array_values(array_filter($allData, function ($item) use ($date) {
                $depAt = $item['departure_at'] ?? '';
                return str_starts_with($depAt, $date);
            }));

            if (empty($allData)) {
                return [
                    'source'        => 'travelpayouts',
                    'bookable'      => false,
                    'data'          => [],
                    'date_prices'   => $datePrices,
                    'redirect_link' => $result['redirect_link'] ?? null,
                ];
            }

            $mapped = collect($allData)->unique(fn($i) => ($i['airline'] ?? '') . ($i['flight_number'] ?? '') . ($i['departure_at'] ?? ''))->values()->map(function ($item, $index) use ($request, $seatClass, $multiplier) {
                $durationMinutes = (int) ($item['duration'] ?? $item['duration_to'] ?? 0);

                $departureAtStr = $item['departure_at'] ?? '';
                $departureTime  = '';
                $arrivalTime    = '';

                if (!empty($departureAtStr) && str_contains($departureAtStr, 'T')) {
                    try {
                        $depTime       = \Carbon\Carbon::parse($departureAtStr);
                        $departureTime = $depTime->format('H:i');
                        $arrTime       = (clone $depTime)->addMinutes($durationMinutes);
                        $arrivalTime   = $arrTime->format('H:i');
                    } catch (\Throwable $e) {
                        $departureTime = '';
                    }
                }

                if (empty($departureTime) || $departureTime === '00:00') {
                    $startHour     = 6 + (($index * 2) % 14);
                    $startMin      = ($index * 15) % 60;
                    $depTime       = \Carbon\Carbon::today()->setTime($startHour, $startMin);
                    $departureTime = $depTime->format('H:i');
                    $arrTime       = (clone $depTime)->addMinutes($durationMinutes > 0 ? $durationMinutes : 120);
                    $arrivalTime   = $arrTime->format('H:i');
                }

                return [
                    'id'            => 'FLT-' . strtoupper(substr(md5(json_encode($item)), 0, 12)),
                    'airline'       => $item['airline'] ?? 'Unknown',
                    'flightNumber'  => ($item['airline'] ?? 'XX') . ($item['flight_number'] ?? '000'),
                    'origin'        => strtoupper($request->input('origin')),
                    'destination'   => strtoupper($request->input('destination')),
                    'departureTime' => $departureTime,
                    'arrivalTime'   => $arrivalTime,
                    'duration'      => $this->formatDuration($durationMinutes),
                    'transitCount'  => $item['transfers'] ?? 0,
                    'price'         => (int) (($item['price'] ?? 0) * $multiplier),
                    'currency'      => 'IDR',
                    'bookingClass'  => $seatClass,
                    'bookable'      => false,
                    'raw'           => $item,
                ];
            })->values()->all();

            return [
                'source'        => 'travelpayouts',
                'bookable'      => false,
                'data'          => $mapped,
                'date_prices'   => $datePrices,
                'redirect_link' => $result['redirect_link'] ?? null,
            ];
        });

        return response()->json([
            'source'        => $payload['source']        ?? 'travelpayouts',
            'bookable'      => $payload['bookable']      ?? false,
            'data'          => $payload['data']          ?? [],
            'date_prices'   => $payload['date_prices']   ?? (object)[],
            'redirect_link' => $payload['redirect_link'] ?? null,
        ]);
    }

    /**
     * Harga termurah per-tanggal untuk date strip.
     * GET /flights/calendar?origin=CGK&destination=DPS&year_month=2026-07&seat_class=Economy
     */
    public function calendar(Request $request)
    {
        $request->validate([
            'origin'      => ['required', 'string', 'size:3'],
            'destination' => ['required', 'string', 'size:3'],
            'year_month'  => ['required', 'string', 'regex:/^\d{4}-\d{2}$/'],
            'seat_class'  => ['nullable', 'string', 'in:Economy,Business,Premium Economy,First'],
        ]);

        $origin     = strtoupper($request->input('origin'));
        $destination = strtoupper($request->input('destination'));
        $yearMonth  = $request->input('year_month');
        $seatClass  = $request->input('seat_class', 'Economy');

        $multiplier = match ($seatClass) {
            'Business'        => 2.5,
            'Premium Economy' => 1.5,
            'First'           => 4.0,
            default           => 1.0,
        };

            $cacheKey = 'calendar_' . md5("{$origin}{$destination}{$yearMonth}{$seatClass}");
        $prices = Cache::store('file')->remember($cacheKey, 1800, function () use ($origin, $destination, $yearMonth, $multiplier) {
            // Bulk calendar (satu bulan)
            $raw = $this->travelpayouts->calendarPrices($origin, $destination, $yearMonth);

            // Untuk tanggal di bulan ini yang tidak ada di calendar, coba prices_for_dates
            $start = \Carbon\Carbon::createFromFormat('Y-m', $yearMonth)->startOfMonth();
            $end   = $start->copy()->endOfMonth();
            $missing = [];
            for ($dt = $start->copy(); $dt->lte($end); $dt->addDay()) {
                $ds = $dt->toDateString();
                if (!isset($raw[$ds])) {
                    $missing[] = $ds;
                }
            }

            // Fetch tanggal yang tidak ada (maks 15 per request agar tidak overload TP)
            foreach (array_slice($missing, 0, 15) as $ds) {
                try {
                    $resp = \Illuminate\Support\Facades\Http::timeout(8)->get(
                        'https://api.travelpayouts.com/aviasales/v3/prices_for_dates',
                        [
                            'origin'       => $origin,
                            'destination'  => $destination,
                            'departure_at' => $ds,
                            'currency'     => 'idr',
                            'limit'        => 1,
                            'sorting'      => 'price',
                            'token'        => config('services.travelpayouts.token'),
                        ]
                    );
                    if ($resp->successful()) {
                        $items = $resp->json('data', []);
                        if (!empty($items)) {
                            $raw[$ds] = (int) ($items[0]['price'] ?? 0);
                        }
                    }
                } catch (\Throwable) {}
            }

            $out = [];
            foreach ($raw as $date => $price) {
                if ($price > 0) {
                    $out[$date] = (int) round($price * $multiplier);
                }
            }
            return $out;
        });

        return response()->json(['data' => $prices]);
    }

    /**
     * Cek harga termurah untuk 1 tanggal spesifik — ringan, limit=1.
     * GET /flights/price-check?origin=X&destination=Y&date=YYYY-MM-DD&seat_class=Economy
     */
    public function priceCheck(Request $request)
    {
        $request->validate([
            'origin'      => ['required', 'string', 'size:3'],
            'destination' => ['required', 'string', 'size:3'],
            'date'        => ['required', 'date_format:Y-m-d'],
            'seat_class'  => ['nullable', 'string'],
        ]);

        $origin      = strtoupper($request->input('origin'));
        $destination = strtoupper($request->input('destination'));
        $date        = $request->input('date');
        $seatClass   = $request->input('seat_class', 'Economy');

        $multiplier = match ($seatClass) {
            'Business'        => 2.5,
            'Premium Economy' => 1.5,
            'First'           => 4.0,
            default           => 1.0,
        };

        $cacheKey = 'price_check_' . md5("{$origin}{$destination}{$date}{$seatClass}");
        $price = Cache::store('file')->remember($cacheKey, 3600, function () use ($origin, $destination, $date, $multiplier) {
            try {
                $resp = \Illuminate\Support\Facades\Http::timeout(8)->get(
                    'https://api.travelpayouts.com/aviasales/v3/prices_for_dates',
                    [
                        'origin'       => $origin,
                        'destination'  => $destination,
                        'departure_at' => $date,
                        'currency'     => 'idr',
                        'limit'        => 1,
                        'sorting'      => 'price',
                        'token'        => config('services.travelpayouts.token'),
                    ]
                );
                if ($resp->successful()) {
                    $items = $resp->json('data', []);
                    if (!empty($items)) {
                        return (int) round(($items[0]['price'] ?? 0) * $multiplier);
                    }
                }
            } catch (\Throwable) {}
            return 0;
        });

        return response()->json(['date' => $date, 'price' => $price]);
    }

    /**
     * Batch endpoint untuk date strip.
     * GET /flights/price-strip?origin=CGK&destination=KNO&date_from=2026-07-21&date_to=2026-07-27&seat_class=Economy
     *
     * Mengembalikan harga termurah per-tanggal dalam rentang date_from–date_to.
     * Semua tanggal di-fetch secara paralel dari Travelpayouts prices_for_dates.
     * Response: { data: { "2026-07-21": { price: 1620998, available: true }, ... } }
     */
    public function priceStrip(Request $request)
    {
        $request->validate([
            'origin'      => ['required', 'string', 'size:3'],
            'destination' => ['required', 'string', 'size:3'],
            'date_from'   => ['required', 'date_format:Y-m-d'],
            'date_to'     => ['required', 'date_format:Y-m-d'],
            'seat_class'  => ['nullable', 'string', 'in:Economy,Business,Premium Economy,First'],
        ]);

        $origin      = strtoupper($request->input('origin'));
        $destination = strtoupper($request->input('destination'));
        $dateFrom    = $request->input('date_from');
        $dateTo      = $request->input('date_to');
        $seatClass   = $request->input('seat_class', 'Economy');

        $multiplier = match ($seatClass) {
            'Business'        => 2.5,
            'Premium Economy' => 1.5,
            'First'           => 4.0,
            default           => 1.0,
        };

        $cacheKey = 'price_strip_' . md5("{$origin}{$destination}{$dateFrom}{$dateTo}{$seatClass}");
        $result = Cache::store('file')->remember($cacheKey, 1800, function () use ($origin, $destination, $dateFrom, $dateTo, $multiplier) {
            $start  = \Carbon\Carbon::parse($dateFrom);
            $end    = \Carbon\Carbon::parse($dateTo);
            $today  = \Carbon\Carbon::today();
            $token  = config('services.travelpayouts.token');
            $output = [];

            // Inisialisasi semua tanggal
            for ($dt = $start->copy(); $dt->lte($end); $dt->addDay()) {
                $ds = $dt->toDateString();
                $output[$ds] = [
                    'price'     => 0,
                    'available' => false,
                ];
            }

            // Kumpulkan bulan unik yang perlu di-fetch
            $monthsNeeded = [];
            for ($dt = $start->copy(); $dt->lte($end); $dt->addDay()) {
                if ($dt->gte($today)) {
                    $ym = $dt->format('Y-m');
                    $monthsNeeded[$ym] = true;
                }
            }

            // Fetch per-BULAN (1-2 call saja, bukan 30)
            // TP prices_for_dates dengan departure_at=YYYY-MM return SEMUA
            // tanggal dalam bulan itu yang punya cache harga
            $allItems = [];
            foreach (array_keys($monthsNeeded) as $ym) {
                try {
                    $resp = Http::timeout(12)->get(
                        'https://api.travelpayouts.com/aviasales/v3/prices_for_dates',
                        [
                            'origin'       => $origin,
                            'destination'  => $destination,
                            'departure_at' => $ym,  // YYYY-MM = seluruh bulan
                            'currency'     => 'idr',
                            'limit'        => 100,
                            'sorting'      => 'price',
                            'token'        => $token,
                        ]
                    );
                    if ($resp->successful()) {
                        $allItems = array_merge($allItems, $resp->json('data', []));
                    }
                } catch (\Throwable $e) {
                    Log::warning("PriceStrip: gagal fetch bulan {$ym}: " . $e->getMessage());
                }
            }

            // Kelompokkan harga termurah per tanggal
            foreach ($allItems as $item) {
                $depAt = $item['departure_at'] ?? '';
                $price = (int) ($item['price'] ?? 0);
                if ($price <= 0 || empty($depAt)) continue;

                $dateKey = substr($depAt, 0, 10);
                if (!isset($output[$dateKey])) continue;

                $adjustedPrice = (int) round($price * $multiplier);
                if ($adjustedPrice > 0) {
                    $current = $output[$dateKey]['price'];
                    if ($current === 0 || $adjustedPrice < $current) {
                        $output[$dateKey] = ['price' => $adjustedPrice, 'available' => true];
                    }
                }
            }

            return $output;
        });

        return response()->json(['data' => $result]);
    }

    /**
     * Proxy autocomplete bandara ke Travelpayouts.
     */
    public function airports(Request $request)
    {
        $term = $request->input('term', '');
        if (strlen($term) < 2) {
            return response()->json([]);
        }

        $cacheKey = 'airports_' . md5($term);

        $results = Cache::store('file')->remember($cacheKey, 3600, function () use ($term) {
            $response = Http::timeout(10)->get(
                'https://autocomplete.travelpayouts.com/places2',
                [
                    'term'    => $term,
                    'locale'  => 'id',
                    'types[]' => 'airport',
                ]
            );

            if (!$response->successful()) {
                return [];
            }

            return collect($response->json())->map(fn($item) => [
                'code'        => $item['code'] ?? '',
                'name'        => $item['name'] ?? '',
                'city'        => $item['main_airport_name'] ?? ($item['city_name'] ?? ''),
                'country'     => $item['country_name'] ?? '',
                'displayName' => ($item['name'] ?? '') . ' (' . ($item['code'] ?? '') . ')',
            ])->filter(fn($a) => !empty($a['code']))->values()->all();
        });

        return response()->json($results);
    }

    private function formatDuration(int $minutes): string
    {
        if ($minutes <= 0) return '-';
        $h = intdiv($minutes, 60);
        $m = $minutes % 60;
        return $h > 0 ? "{$h}j {$m}m" : "{$m}m";
    }

    /**
     * Hasilkan mock flights realistis untuk rute Indonesia
     * ketika Travelpayouts tidak punya data cache.
     */
    private function generateMockFlights(string $origin, string $destination, string $date, string $seatClass = 'Economy'): array
    {
        // Durasi penerbangan (menit) antar kota utama Indonesia
        $durationMap = [
            'CGK-DPS' => 90,  'DPS-CGK' => 90,
            'CGK-SUB' => 65,  'SUB-CGK' => 65,
            'CGK-UPG' => 155, 'UPG-CGK' => 155,
            'CGK-MDC' => 180, 'MDC-CGK' => 180,
            'CGK-KNO' => 120, 'KNO-CGK' => 120,
            'CGK-BPN' => 145, 'BPN-CGK' => 145,
            'CGK-PLM' => 75,  'PLM-CGK' => 75,
            'CGK-JOG' => 55,  'JOG-CGK' => 55,
            'CGK-SRG' => 60,  'SRG-CGK' => 60,
            'CGK-PNK' => 100, 'PNK-CGK' => 100,
            'CGK-BDJ' => 130, 'BDJ-CGK' => 130,
            'DPS-SUB' => 55,  'SUB-DPS' => 55,
            'DPS-UPG' => 95,  'UPG-DPS' => 95,
            'DPS-MDC' => 130, 'MDC-DPS' => 130,
            'DPS-KNO' => 165, 'KNO-DPS' => 165,
            'DPS-BPN' => 100, 'BPN-DPS' => 100,
            'SUB-UPG' => 90,  'UPG-SUB' => 90,
            'SUB-MDC' => 130, 'MDC-SUB' => 130,
            'SUB-BPN' => 105, 'BPN-SUB' => 105,
            'SUB-KNO' => 155, 'KNO-SUB' => 155,
            'UPG-MDC' => 80,  'MDC-UPG' => 80,
            'UPG-KNO' => 155, 'KNO-UPG' => 155,
            'UPG-BPN' => 70,  'BPN-UPG' => 70,
            'UPG-BDJ' => 65,  'BDJ-UPG' => 65,
            'MDC-BPN' => 100, 'BPN-MDC' => 100,
            'KNO-PLM' => 90,  'PLM-KNO' => 90,
            'KNO-BDJ' => 140, 'BDJ-KNO' => 140,
            'BPN-MDC' => 100, 'MDC-BPN' => 100,
            // Rute internasional populer
            'CGK-SIN' => 100, 'SIN-CGK' => 100,
            'CGK-KUL' => 120, 'KUL-CGK' => 120,
            'CGK-BKK' => 195, 'BKK-CGK' => 195,
            'DPS-SIN' => 145, 'SIN-DPS' => 145,
            'DPS-KUL' => 165, 'KUL-DPS' => 165,
            'SUB-SIN' => 130, 'SIN-SUB' => 130,
            'CGK-HKG' => 255, 'HKG-CGK' => 255,
            'CGK-NRT' => 375, 'NRT-CGK' => 375,
        ];

        // Template maskapai: [kode IATA, nama, prefix nomor penerbangan, multiplier harga]
        $airlines = [
            ['QG', 'Citilink',         'QG', 0.85],
            ['JT', 'Lion Air',         'JT', 0.80],
            ['ID', 'Batik Air',        'ID', 1.10],
            ['IU', 'Super Air Jet',    'IU', 0.75],
            ['GA', 'Garuda Indonesia', 'GA', 1.45],
            ['SJ', 'Sriwijaya Air',    'SJ', 0.90],
        ];

        $routeKey = "{$origin}-{$destination}";
        $durationMin = $durationMap[$routeKey] ?? 120;

        // Harga dasar berdasarkan durasi (kasar: Rp 8.000/menit + base 250.000)
        $basePrice = 250000 + ($durationMin * 8000);

        // Jadwal keberangkatan yang realistis
        $departureTimes = ['05:30', '07:00', '08:45', '10:30', '12:00', '13:30', '15:00', '16:45', '18:30', '20:00'];
        shuffle($departureTimes);
        $departureTimes = array_slice($departureTimes, 0, 5);
        sort($departureTimes);

        // Pilih 4–5 maskapai acak
        shuffle($airlines);
        $selectedAirlines = array_slice($airlines, 0, count($departureTimes));

        // Price multiplier for travel classes
        $multiplier = 1.0;
        if ($seatClass === 'Premium Economy') {
            $multiplier = 1.5;
        } elseif ($seatClass === 'Business') {
            $multiplier = 2.5;
        } elseif ($seatClass === 'First') {
            $multiplier = 4.0;
        }

        $flights = [];
        foreach ($departureTimes as $i => $depTime) {
            $airline    = $selectedAirlines[$i] ?? $airlines[0];
            $flightNum  = rand(100, 999);
            $price      = (int) round($basePrice * $airline[3] * $multiplier * (0.92 + lcg_value() * 0.16));
            // Bulatkan ke kelipatan 50.000
            $price      = (int) (round($price / 50000) * 50000);

            [$h, $m]    = explode(':', $depTime);
            $depCarbon  = \Carbon\Carbon::createFromDate(null, null, null)
                              ->setTime((int)$h, (int)$m);
            $arrCarbon  = (clone $depCarbon)->addMinutes($durationMin);

            $transfers = 0;
            // Rute sangat jauh kemungkinan transit
            if ($durationMin > 200 && $airline[0] !== 'GA' && lcg_value() > 0.6) {
                $transfers = 1;
                $arrCarbon->addMinutes(90); // waktu transit tambahan
            }

            $flights[] = [
                'id'            => 'MOCK-' . strtoupper(substr(md5($origin . $destination . $depTime . $airline[0]), 0, 10)),
                'airline'       => $airline[0],
                'flightNumber'  => $airline[2] . $flightNum,
                'origin'        => $origin,
                'destination'   => $destination,
                'departureTime' => $depCarbon->format('H:i'),
                'arrivalTime'   => $arrCarbon->format('H:i'),
                'duration'      => $this->formatDuration($durationMin + ($transfers > 0 ? 90 : 0)),
                'transitCount'  => $transfers,
                'price'         => $price,
                'currency'      => 'IDR',
                'bookingClass'  => $seatClass,
                'raw'           => [],
            ];
        }

        // Urutkan dari harga termurah
        usort($flights, fn($a, $b) => $a['price'] <=> $b['price']);

        return $flights;
    }
}
