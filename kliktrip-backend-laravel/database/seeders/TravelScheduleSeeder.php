<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use App\Models\Province;
use App\Models\City;
use App\Models\Vehicle;
use App\Models\Driver;
use App\Models\TravelRoute;
use App\Models\TravelSchedule;

/**
 * TravelScheduleSeeder
 * --------------------
 * Mengisi rute + jadwal travel untuk RENTANG TANGGAL (default 60 hari ke depan,
 * mulai hari ini), sehingga tanggal apa pun yang dipilih user punya jadwal.
 *
 * Memakai BULK INSERT (chunk) agar cepat walau DB remote (Supabase Tokyo) —
 * insert baris-per-baris terlalu lambat karena latensi jaringan.
 *
 * IDEMPOTENT: jadwal yang sudah ada (kombinasi travel_route_id + departure_time
 * sama) dilewati, jadi aman dijalankan berkali-kali / menambah hari.
 *
 * Jalankan: php artisan db:seed --class=TravelScheduleSeeder --force
 */
class TravelScheduleSeeder extends Seeder
{
    /** Jumlah hari ke depan jadwal dibuat (mulai hari ini, inklusif). */
    private const DAYS_AHEAD = 60;

    /** Jam keberangkatan per rute per hari. */
    private const DEPARTURE_TIMES = ['05:30', '09:15', '12:00', '15:40', '18:30', '21:00'];

    public function run(): void
    {
        // 1. Provinces & Cities (firstOrCreate → pakai ulang bila sudah ada)
        $sulut     = Province::firstOrCreate(['name' => 'Sulawesi Utara']);
        $goronprov = Province::firstOrCreate(['name' => 'Gorontalo']);
        $sulsel    = Province::firstOrCreate(['name' => 'Sulawesi Selatan']);
        $sultra    = Province::firstOrCreate(['name' => 'Sulawesi Tenggara']);
        $dki       = Province::firstOrCreate(['name' => 'DKI Jakarta']);
        $jabar     = Province::firstOrCreate(['name' => 'Jawa Barat']);

        $manado     = City::firstOrCreate(['name' => 'Manado'],     ['province_id' => $sulut->id]);
        $kotamobagu = City::firstOrCreate(['name' => 'Kotamobagu'], ['province_id' => $sulut->id]);
        $gorontalo  = City::firstOrCreate(['name' => 'Gorontalo'],  ['province_id' => $goronprov->id]);
        $makassar   = City::firstOrCreate(['name' => 'Makassar'],   ['province_id' => $sulsel->id]);
        $kendari    = City::firstOrCreate(['name' => 'Kendari'],    ['province_id' => $sultra->id]);
        $jakarta    = City::firstOrCreate(['name' => 'Jakarta'],    ['province_id' => $dki->id]);
        $bandung    = City::firstOrCreate(['name' => 'Bandung'],    ['province_id' => $jabar->id]);
        $tangerang  = City::firstOrCreate(['name' => 'Tangerang'],  ['province_id' => $jabar->id]);

        // 2. Vehicles
        $vehicles = [];
        foreach ([
            ['Toyota HiAce Commuter 01', 'DB 7021 AA', 'COMMUTER', 15],
            ['Toyota HiAce Commuter 02', 'DB 7023 AC', 'COMMUTER', 15],
            ['Toyota HiAce Premio 01',   'DB 7022 AB', 'PREMIO',   11],
            ['Toyota HiAce Premio 02',   'DB 7024 AD', 'PREMIO',   11],
        ] as [$name, $plate, $type, $cap]) {
            $vehicles[] = Vehicle::firstOrCreate(
                ['license_plate' => $plate],
                ['name' => $name, 'type' => $type, 'capacity' => $cap, 'is_active' => true]
            );
        }

        // 3. Drivers
        $drivers = [];
        foreach ([
            ['Budi Santoso', '081122334455', '950212345678'],
            ['Ahmad Fauzi',  '081122334456', '950212345679'],
            ['Rudi Hartono', '081122334457', '950212345680'],
            ['Siti Rahayu',  '081122334458', '950212345681'],
        ] as [$name, $phone, $lic]) {
            $drivers[] = Driver::firstOrCreate(
                ['license_number' => $lic],
                ['name' => $name, 'phone' => $phone, 'is_active' => true]
            );
        }

        // 4. Routes
        $cities = compact(
            'manado', 'kotamobagu', 'gorontalo', 'makassar', 'kendari',
            'jakarta', 'bandung', 'tangerang'
        );

        $routeData = [
            ['kotamobagu', 'manado',      180,  300,  500000],
            ['kotamobagu', 'gorontalo',   220,  420,  600000],
            ['kotamobagu', 'makassar',   1800, 2640, 1200000],
            ['kotamobagu', 'kendari',    1600, 2400, 1350000],
            ['manado',     'kotamobagu',  180,  300,  500000],
            ['manado',     'gorontalo',   370,  600,  750000],
            ['manado',     'makassar',   1900, 2880, 1000000],
            ['manado',     'kendari',    1750, 2640, 1500000],
            ['gorontalo',  'manado',      370,  600,  750000],
            ['gorontalo',  'kotamobagu',  220,  420,  600000],
            ['gorontalo',  'makassar',   1400, 2280, 1100000],
            ['gorontalo',  'kendari',    1200, 2040, 1200000],
            ['makassar',   'manado',     1900, 2880, 1000000],
            ['makassar',   'kotamobagu', 1800, 2640, 1200000],
            ['makassar',   'gorontalo',  1400, 2280, 1100000],
            ['makassar',   'kendari',     600, 1500,  900000],
            ['kendari',    'manado',     1750, 2640, 1500000],
            ['kendari',    'kotamobagu', 1600, 2400, 1350000],
            ['kendari',    'gorontalo',  1200, 2040, 1200000],
            ['kendari',    'makassar',    600, 1500,  900000],
            ['jakarta',    'bandung',     150,  180,  125000],
            ['tangerang',  'bandung',     180,  220,  150000],
            ['bandung',    'jakarta',     150,  180,  125000],
        ];

        $routes = [];
        foreach ($routeData as [$dep, $arr, $dist, $dur, $price]) {
            $route = TravelRoute::firstOrCreate(
                ['departure_city_id' => $cities[$dep]->id, 'arrival_city_id' => $cities[$arr]->id],
                ['distance_km' => $dist, 'duration_minutes' => $dur]
            );
            $routes[] = ['route' => $route, 'dur' => $dur, 'price' => $price];
        }

        // 5. Kumpulkan jadwal yang SUDAH ADA (idempotent) → set kunci route|waktu.
        $existing = [];
        foreach (TravelSchedule::select('travel_route_id', 'departure_time')->get() as $s) {
            $existing[$s->travel_route_id . '|' . $s->departure_time->format('Y-m-d H:i:s')] = true;
        }

        // 6. Bangun baris untuk seluruh rentang tanggal, lalu bulk insert.
        $nowStr = now()->format('Y-m-d H:i:s');
        $rows = [];
        $idx = 0;
        for ($d = 0; $d <= self::DAYS_AHEAD; $d++) {
            $day = today()->addDays($d);
            foreach ($routes as $r) {
                foreach (self::DEPARTURE_TIMES as $time) {
                    [$h, $m] = explode(':', $time);
                    $dep = $day->copy()->setTime((int) $h, (int) $m, 0);
                    $depStr = $dep->format('Y-m-d H:i:s');
                    $key = $r['route']->id . '|' . $depStr;
                    if (isset($existing[$key])) {
                        $idx++;
                        continue;
                    }
                    $veh = $vehicles[$idx % count($vehicles)];
                    $drv = $drivers[$idx % count($drivers)];
                    $rows[] = [
                        'id'              => (string) Str::uuid(),
                        'vehicle_id'      => $veh->id,
                        'travel_route_id' => $r['route']->id,
                        'driver_id'       => $drv->id,
                        'departure_time'  => $depStr,
                        'arrival_time'    => $dep->copy()->addMinutes($r['dur'])->format('Y-m-d H:i:s'),
                        'available_seats' => $veh->capacity,
                        'price'           => $r['price'],
                        'status'          => 'SCHEDULED',
                        'created_at'      => $nowStr,
                        'updated_at'      => $nowStr,
                    ];
                    $idx++;
                }
            }
        }

        // 7. Bulk insert per 500 baris (satu query per chunk → cepat di DB remote).
        foreach (array_chunk($rows, 500) as $chunk) {
            TravelSchedule::insert($chunk);
        }

        $this->command->info(
            'TravelScheduleSeeder selesai. Ditambahkan: ' . count($rows) .
            ' jadwal. Total sekarang: ' . TravelSchedule::count()
        );
    }
}
