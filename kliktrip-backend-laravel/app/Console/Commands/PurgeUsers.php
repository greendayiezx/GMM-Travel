<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

/**
 * Hapus SEMUA akun user (Clerk + lokal) untuk keperluan testing.
 * Setelah ini, email yang sudah terdaftar bisa dipakai mendaftar lagi.
 *
 * DESTRUKTIF & TIDAK BISA DIBATALKAN.
 *   php artisan users:purge --force
 */
class PurgeUsers extends Command
{
    protected $signature = 'users:purge {--force : Jalankan tanpa konfirmasi}';
    protected $description = 'Hapus SEMUA akun user Clerk + user lokal (untuk testing)';

    public function handle(): int
    {
        $secret = config('services.clerk.secret_key');
        if (empty($secret)) {
            $this->error('CLERK_SECRET_KEY belum diset.');
            return self::FAILURE;
        }

        if (!$this->option('force')) {
            $this->error('Ini menghapus SEMUA akun & tidak bisa dibatalkan.');
            $this->line('Jalankan dengan: php artisan users:purge --force');
            return self::FAILURE;
        }

        $deleted = 0;
        $failed  = 0;

        // Ambil & hapus user Clerk secara batch. Karena tiap user dihapus,
        // fetch berikutnya (offset 0) mengambil sisa yang belum terhapus.
        while (true) {
            $resp = Http::withToken($secret)->timeout(20)
                ->get('https://api.clerk.com/v1/users', ['limit' => 100]);

            if (!$resp->ok()) {
                $this->error('Gagal ambil daftar user Clerk: HTTP ' . $resp->status());
                break;
            }

            $users = $resp->json();
            if (!is_array($users) || count($users) === 0) {
                break;
            }

            foreach ($users as $u) {
                $id = $u['id'] ?? null;
                if (!$id) continue;

                $del = Http::withToken($secret)->timeout(20)
                    ->delete("https://api.clerk.com/v1/users/{$id}");

                if ($del->successful()) {
                    $deleted++;
                    $this->line("  ✓ Clerk user dihapus: {$id}");
                } else {
                    $failed++;
                    $this->warn("  ✗ Gagal hapus {$id}: HTTP " . $del->status());
                }
            }

            // Kalau batch < 100, berarti sudah batch terakhir.
            if (count($users) < 100) break;
        }

        // Hapus user lokal yang tertaut Clerk (record hasil sync).
        $localDeleted = User::whereNotNull('clerk_id')->delete();

        $this->newLine();
        $this->info("Selesai.");
        $this->line("  Clerk user dihapus : {$deleted}");
        $this->line("  Gagal              : {$failed}");
        $this->line("  User lokal dihapus : {$localDeleted}");
        $this->newLine();
        $this->line('Sekarang email yang tadi terdaftar bisa dipakai mendaftar lagi.');

        return self::SUCCESS;
    }
}
