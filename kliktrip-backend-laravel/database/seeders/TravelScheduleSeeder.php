<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Province;
use App\Models\City;
use App\Models\Vehicle;
use App\Models\Driver;
use App\Models\TravelRoute;
use App\Models\TravelSchedule;

/**
 * TravelScheduleSeeder
 * --------------------
 * Mengisi rute + jadwal travel secara IDEMPOTENT (aman dijalankan berkali-kali).
 * Berbeda dari DatabaseSeeder yang memakai create() dan gagal bila data sudah ada,
 * seeder ini memakai firstOrCreate() sehingga data yang sudah ada dipakai ulang,
 * dan jadwal hanya dibuat untuk rute yang belum punya jadwal.
 *
 * Jalankan di production: php artisan db:seed --class=TravelScheduleSeeder --force
 */
class TravelScheduleSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Provinces & Cities (firstOrCreate → pakai ulang bila sudah ada)
        $sulut     = Province::firstOrCreate(['name' => 'Sulawesi Utara']);
        $goronprov = Province::firstOrCreate(['name' => 'Gorontalo']);
        $sulsel    = Province::firstOrCreate(['name' => 'Sulawesi Selatan']);
        $sultra    = Province::firstOrCreate(['name' => 'Sulawesi Tenggara']);

        $manado     = City::firstOrCreate(['name' => 'Manado'],     ['province_id' => $sulut->id]);
        $kotamobagu = City::firstOrCreate(['name' => 'Kotamobagu'], ['province_id' => $sulut->id]);
        $gorontalo  = City::firstOrCreate(['name' => 'Gorontalo'],  ['province_id' => $goronprov->id]);
        $makassar   = City::firstOrCreate(['name' => 'Makassar'],   ['province_id' => $sulsel->id]);
        $kendari    = City::firstOrCreate(['name' => 'Kendari'],    ['province_id' => $sultra->id]);

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
            ['Budi Santoso',  '081122334455', '950212345678'],
            ['Ahmad Fauzi',   '081122334456', '950212345679'],
            ['Rudi Hartono',  '081122334457', '950212345680'],
            ['Siti Rahayu',   '081122334458', '950212345681'],
        ] as [$name, $phone, $lic]) {
            $drivers[] = Driver::firstOrCreate(
                ['license_number' => $lic],
                ['name' => $name, 'phone' => $phone, 'is_active' => true]
            );
        }

        // 4. Routes + Schedules
        $cities = compact('manado', 'kotamobagu', 'gorontalo', 'makassar', 'kendari');

        $routeData = [
            ['kotamobagu', 'manado',     180,  300,  500000],
            ['kotamobagu', 'gorontalo',  220,  420,  600000],
            ['kotamobagu', 'makassar',  1800, 2640, 1200000],
            ['kotamobagu', 'kendari',   1600, 2400, 1350000],
            ['manado',     'kotamobagu', 180,  300,  500000],
            ['manado',     'gorontalo',  370,  600,  750000],
            ['manado',     'makassar',  1900, 2880, 1000000],
            ['manado',     'kendari',   1750, 2640, 1500000],
            ['gorontalo',  'manado',     370,  600,  750000],
            ['gorontalo',  'kotamobagu', 220,  420,  600000],
            ['gorontalo',  'makassar',  1400, 2280, 1100000],
            ['gorontalo',  'kendari',   1200, 2040, 1200000],
            ['makassar',   'manado',    1900, 2880, 1000000],
            ['makassar',   'kotamobagu',1800, 2640, 1200000],
            ['makassar',   'gorontalo', 1400, 2280, 1100000],
            ['makassar',   'kendari',    600, 1500,  900000],
            ['kendari',    'manado',    1750, 2640, 1500000],
            ['kendari',    'kotamobagu',1600, 2400, 1350000],
            ['kendari',    'gorontalo', 1200, 2040, 1200000],
            ['kendari',    'makassar',   600, 1500,  900000],
        ];

        $departureTimes = ['05:30', '09:15', '12:00', '15:40', '18:30', '21:00'];

        $scheduleIndex = 0;
        foreach ($routeData as [$dep, $arr, $dist, $dur, $price]) {
            $route = TravelRoute::firstOrCreate(
                [
                    'departure_city_id' => $cities[$dep]->id,
                    'arrival_city_id'   => $cities[$arr]->id,
                ],
                ['distance_km' => $dist, 'duration_minutes' => $dur]
            );

            // Idempotent: lewati bila rute ini sudah punya jadwal.
            if (TravelSchedule::where('travel_route_id', $route->id)->exists()) {
                $scheduleIndex += count($departureTimes);
                continue;
            }

            foreach ($departureTimes as $time) {
                [$h, $m] = explode(':', $time);
                $depTime = now()->addDays(1)->setTime((int)$h, (int)$m, 0);
                $arrTime = (clone $depTime)->addMinutes($dur);

                TravelSchedule::create([
                    'vehicle_id'      => $vehicles[$scheduleIndex % count($vehicles)]->id,
                    'travel_route_id' => $route->id,
                    'driver_id'       => $drivers[$scheduleIndex % count($drivers)]->id,
                    'departure_time'  => $depTime,
                    'arrival_time'    => $arrTime,
                    'available_seats' => $vehicles[$scheduleIndex % count($vehicles)]->capacity,
                    'price'           => $price,
                    'status'          => 'SCHEDULED',
                ]);
                $scheduleIndex++;
            }
        }

        $this->command->info('TravelScheduleSeeder selesai. Total jadwal: ' . TravelSchedule::count());
    }
}
