<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

/**
 * Orchestrator pencarian tiket. Panggil Duffel dulu; jika kosong / gagal,
 * fallback ke Travelpayouts. Frontend hanya melihat satu format seragam:
 *
 *   {
 *     source:   'duffel' | 'travelpayouts',
 *     bookable: bool,
 *     offers:   FlightResult[]
 *   }
 */
class FlightSearchOrchestrator
{
    public function __construct(
        private DuffelService        $duffel,
        private TravelpayoutsService $travelpayouts,
    ) {}

    /** Kode IATA bandara yang ada di Indonesia */
    private array $indonesianAirports = [
        'CGK','HLP','SUB','DPS','UPG','MDC','KNO','BPN','PLM','JOG','SRG','PNK',
        'BDJ','BTH','BTJ','PDG','MES','DJJ','AMQ','KDI','PLW','LOP','TIM','SOC',
        'SRI','KOE','MOF','TKG','PGK','TJQ','GNS','BKS','MLG','TRK','TTE','LUW',
        'MKQ','BIK','FKQ','NBX','LBJ','WMX',
    ];

    private function isDomesticIndonesia(string $origin, string $destination): bool
    {
        return in_array(strtoupper($origin), $this->indonesianAirports, true)
            && in_array(strtoupper($destination), $this->indonesianAirports, true);
    }

    public function search(
        string $origin,
        string $destination,
        string $departureDate,
        int    $adults    = 1,
        int    $children  = 0,
        int    $infants   = 0,
        string $cabinClass = 'economy'
    ): array {
        $isDomestic = $this->isDomesticIndonesia($origin, $destination);

        // Rute DOMESTIK Indonesia: Travelpayouts lebih lengkap (Lion Air, Citilink,
        // Batik Air, dll.) dan harganya akurat. Duffel test-mode hanya punya sedikit
        // maskapai dengan harga tidak riil untuk rute dalam negeri.
        if ($isDomestic) {
            $tpRaw = $this->travelpayouts->searchRaw($origin, $destination, $departureDate);
            Log::info('FlightSearchOrchestrator: domestik → Travelpayouts primary', [
                'route' => "{$origin}-{$destination}",
                'count' => count($tpRaw),
            ]);
            return [
                'source'        => 'travelpayouts',
                'bookable'      => false,
                'raw'           => $tpRaw,
                'redirect_link' => $this->travelpayouts->buildRedirectLink(
                    $origin, $destination, $departureDate, $adults
                ),
            ];
        }

        // Rute INTERNASIONAL: Duffel dulu (live offers, bisa booking langsung)
        $duffelOffers = $this->duffel->searchOffers(
            $origin, $destination, $departureDate,
            $adults, $children, $infants, $cabinClass
        );

        if (!empty($duffelOffers)) {
            return [
                'source'   => 'duffel',
                'bookable' => true,
                'offers'   => $duffelOffers,
            ];
        }

        // Fallback internasional: Travelpayouts
        $tpRaw = $this->travelpayouts->searchRaw($origin, $destination, $departureDate);
        Log::info('FlightSearchOrchestrator: internasional → fallback Travelpayouts', [
            'route' => "{$origin}-{$destination}",
            'count' => count($tpRaw),
        ]);
        return [
            'source'        => 'travelpayouts',
            'bookable'      => false,
            'raw'           => $tpRaw,
            'redirect_link' => $this->travelpayouts->buildRedirectLink(
                $origin, $destination, $departureDate, $adults
            ),
        ];
    }
}
