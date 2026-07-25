<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Role;
use App\Models\User;
use App\Models\Province;
use App\Models\City;
use App\Models\Vehicle;
use App\Models\Driver;
use App\Models\TravelRoute;
use App\Models\TravelSchedule;
use App\Models\TourCategory;
use App\Models\TourPackage;
use App\Models\PaymentMethod;
use App\Models\Setting;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Roles
        $adminRole  = Role::create(['name' => 'Admin',  'slug' => 'admin']);
        $userRole   = Role::create(['name' => 'User',   'slug' => 'user']);
        $driverRole = Role::create(['name' => 'Driver', 'slug' => 'driver']);

        // 2. Users
        User::create([
            'role_id'  => $adminRole->id,
            'name'     => 'Administrator GMM Travel',
            'email'    => 'admin@gmmtravel.com',
            'password' => bcrypt('password123'),
            'phone'    => '081234567890',
        ]);
        User::create([
            'role_id'  => $userRole->id,
            'name'     => 'John Doe',
            'email'    => 'john.doe@example.com',
            'password' => bcrypt('password123'),
            'phone'    => '081234567891',
        ]);

        // 3. Provinces & Cities
        $sulut     = Province::create(['name' => 'Sulawesi Utara']);
        $goronprov = Province::create(['name' => 'Gorontalo']);
        $sulsel    = Province::create(['name' => 'Sulawesi Selatan']);
        $sultra    = Province::create(['name' => 'Sulawesi Tenggara']);

        $manado     = City::create(['province_id' => $sulut->id,     'name' => 'Manado']);
        $kotamobagu = City::create(['province_id' => $sulut->id,     'name' => 'Kotamobagu']);
        $gorontalo  = City::create(['province_id' => $goronprov->id, 'name' => 'Gorontalo']);
        $makassar   = City::create(['province_id' => $sulsel->id,    'name' => 'Makassar']);
        $kendari    = City::create(['province_id' => $sultra->id,    'name' => 'Kendari']);

        // 4. Vehicles
        $vehicles = [];
        foreach ([
            ['Toyota HiAce Commuter 01', 'DB 7021 AA', 'COMMUTER', 15],
            ['Toyota HiAce Commuter 02', 'DB 7023 AC', 'COMMUTER', 15],
            ['Toyota HiAce Premio 01',   'DB 7022 AB', 'PREMIO',   11],
            ['Toyota HiAce Premio 02',   'DB 7024 AD', 'PREMIO',   11],
        ] as [$name, $plate, $type, $cap]) {
            $vehicles[] = Vehicle::create([
                'name'          => $name,
                'license_plate' => $plate,
                'type'          => $type,
                'capacity'      => $cap,
                'is_active'     => true,
            ]);
        }

        // 5. Drivers
        $drivers = [];
        foreach ([
            ['Budi Santoso',  '081122334455', '950212345678'],
            ['Ahmad Fauzi',   '081122334456', '950212345679'],
            ['Rudi Hartono',  '081122334457', '950212345680'],
            ['Siti Rahayu',   '081122334458', '950212345681'],
        ] as [$name, $phone, $lic]) {
            $drivers[] = Driver::create([
                'name'           => $name,
                'phone'          => $phone,
                'license_number' => $lic,
                'is_active'      => true,
            ]);
        }

        // 6. Travel Routes — semua kombinasi 5 kota (20 rute)
        // Format: [departure, arrival, distance_km, duration_minutes, price_executive]
        $cities = compact('manado', 'kotamobagu', 'gorontalo', 'makassar', 'kendari');

        $routeData = [
            // Dari Kotamobagu
            ['kotamobagu', 'manado',     180,  300,  500000],
            ['kotamobagu', 'gorontalo',  220,  420,  600000],
            ['kotamobagu', 'makassar',  1800, 2640, 1200000],
            ['kotamobagu', 'kendari',   1600, 2400, 1350000],
            // Dari Manado
            ['manado',     'kotamobagu', 180,  300,  500000],
            ['manado',     'gorontalo',  370,  600,  750000],
            ['manado',     'makassar',  1900, 2880, 1000000],
            ['manado',     'kendari',   1750, 2640, 1500000],
            // Dari Gorontalo
            ['gorontalo',  'manado',     370,  600,  750000],
            ['gorontalo',  'kotamobagu', 220,  420,  600000],
            ['gorontalo',  'makassar',  1400, 2280, 1100000],
            ['gorontalo',  'kendari',   1200, 2040, 1200000],
            // Dari Makassar
            ['makassar',   'manado',    1900, 2880, 1000000],
            ['makassar',   'kotamobagu',1800, 2640, 1200000],
            ['makassar',   'gorontalo', 1400, 2280, 1100000],
            ['makassar',   'kendari',    600, 1500,  900000],
            // Dari Kendari
            ['kendari',    'manado',    1750, 2640, 1500000],
            ['kendari',    'kotamobagu',1600, 2400, 1350000],
            ['kendari',    'gorontalo', 1200, 2040, 1200000],
            ['kendari',    'makassar',   600, 1500,  900000],
        ];

        // Jam keberangkatan (sesuai 6 kartu tiket di frontend)
        $departureTimes = ['05:30', '09:15', '12:00', '15:40', '18:30', '21:00'];

        $scheduleIndex = 0;
        foreach ($routeData as [$dep, $arr, $dist, $dur, $price]) {
            $route = TravelRoute::create([
                'departure_city_id' => $cities[$dep]->id,
                'arrival_city_id'   => $cities[$arr]->id,
                'distance_km'       => $dist,
                'duration_minutes'  => $dur,
            ]);

            // Buat 6 jadwal per rute (1 per jam keberangkatan)
            foreach ($departureTimes as $timeIndex => $time) {
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

        // 7. Tour Categories & Packages
        $adventure = TourCategory::create(['name' => 'Petualangan & Alam',  'slug' => 'petualangan-alam']);
        $culture   = TourCategory::create(['name' => 'Budaya & Sejarah',    'slug' => 'budaya-sejarah']);

        TourPackage::create([
            'tour_category_id' => $adventure->id,
            'name'             => 'Trip Bunaken Marine Park',
            'slug'             => 'trip-bunaken-marine-park',
            'description'      => 'Jelajahi keindahan terumbu karang kelas dunia di Taman Nasional Bunaken.',
            'meeting_point'    => 'Pelabuhan Manado Marina',
            'includes'         => 'Tiket kapal, alat snorkeling, makan siang, instruktur berlisensi',
            'excludes'         => 'Pengeluaran pribadi, dokumentasi underwater tambahan',
            'terms'            => 'Minimal 2 peserta, booking paling lambat H-3 keberangkatan',
            'thumbnail'        => 'assets/dest-manado.png',
            'is_featured'      => true,
            'is_active'        => true,
        ]);

        // 8. Payment Methods
        foreach ([
            ['BNI Virtual Account',     'BNI_VA',     'midtrans'],
            ['BRI Virtual Account',     'BRI_VA',     'midtrans'],
            ['Mandiri Virtual Account', 'MANDIRI_VA', 'midtrans'],
            ['GoPay',                   'GOPAY',      'midtrans'],
            ['OVO',                     'OVO',        'midtrans'],
            ['DANA',                    'DANA',       'midtrans'],
            ['QRIS',                    'QRIS',       'midtrans'],
        ] as [$name, $code, $gateway]) {
            PaymentMethod::create([
                'name'      => $name,
                'code'      => $code,
                'gateway'   => strtoupper($gateway),
                'logo'      => strtolower($code) . '.png',
                'is_active' => true,
            ]);
        }

        // 9. Settings
        Setting::create(['key' => 'app_name',        'value' => 'GMM Travel']);
        Setting::create(['key' => 'company_address', 'value' => 'Jl. Boulevard Raya No. 45, Manado, Sulawesi Utara']);
        Setting::create(['key' => 'support_phone',   'value' => '+62 812-3456-7890']);

        // 10. Katalog paket (idempotent — aman dijalankan ulang)
        $this->call(PackageCatalogSeeder::class);
    }
}
