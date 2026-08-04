<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use App\Models\TourCatalog;

/**
 * TourCatalogSeeder
 * -----------------
 * Impor katalog paket wisata dari database/data/wisata.json (100 paket, sama
 * dengan yang sebelumnya jadi asset lokal di mobile) ke tabel tour_catalogs.
 *
 * Idempotent: kosongkan lalu isi ulang (bulk insert, cepat di DB remote).
 *
 * Jalankan: php artisan db:seed --class=TourCatalogSeeder --force
 */
class TourCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('data/wisata.json');
        if (! is_file($path)) {
            $this->command->warn('wisata.json tidak ditemukan di database/data — dilewati.');
            return;
        }

        $packages = json_decode(file_get_contents($path), true);
        if (! is_array($packages)) {
            $this->command->error('wisata.json tidak valid.');
            return;
        }

        $now  = now()->format('Y-m-d H:i:s');
        $rows = [];
        foreach (array_values($packages) as $i => $p) {
            $rows[] = [
                'id'          => (string) Str::uuid(),
                'external_id' => 'wisata-' . $i,               // kunci internal unik
                'kategori'    => strtoupper($p['kategori'] ?? 'DOMESTIK'),
                'nama_paket'  => $p['nama_paket'] ?? '',
                'payload'     => json_encode($p, JSON_UNESCAPED_UNICODE),
                'active'      => true,
                'created_at'  => $now,
                'updated_at'  => $now,
            ];
        }

        // Segarkan penuh (idempotent).
        TourCatalog::query()->delete();
        foreach (array_chunk($rows, 100) as $chunk) {
            TourCatalog::insert($chunk);
        }

        $this->command->info('TourCatalogSeeder selesai. Paket ter-seed: ' . TourCatalog::count());
    }
}
