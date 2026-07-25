<?php

namespace Database\Seeders;

use App\Models\PackageCatalog;
use Illuminate\Database\Seeder;

/**
 * Seed katalog paket dari database/data/packages.json.
 *
 * Regenerate packages.json dari frontend:
 *   node scripts/extract-packages.js
 *
 * Idempotent: pakai updateOrCreate agar aman dijalankan ulang saat katalog
 * frontend berubah (regenerate packages.json lalu seed lagi).
 */
class PackageCatalogSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('data/packages.json');
        if (!file_exists($path)) {
            $this->command->warn('packages.json tidak ditemukan — lewati.');
            return;
        }

        $packages = json_decode(file_get_contents($path), true);
        if (!is_array($packages)) {
            $this->command->error('packages.json tidak valid.');
            return;
        }

        foreach ($packages as $p) {
            PackageCatalog::updateOrCreate(
                ['name' => $p['name']],
                [
                    'base_price'        => $p['base_price'] ?? 0,
                    'price_categories'  => $p['price_categories'] ?? null,
                    'single_supplement' => $p['single_supplement'] ?? null,
                    'duration'          => $p['duration'] ?? null,
                    'max_pax'           => $p['max_pax'] ?? null,
                    'active'            => true,
                ]
            );
        }

        $this->command->info(count($packages) . ' paket ter-seed ke package_catalogs.');
    }
}
