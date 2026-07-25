<?php

namespace App\Console\Commands;

use App\Models\Payment;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * CleanDummyData
 * --------------
 * Menghapus data dummy/seeder (user contoh + booking + pembayarannya) sebelum
 * production, agar tidak tercampur dengan data user asli.
 *
 * Menargetkan HANYA email dummy (@example.com) — data real tidak tersentuh.
 * Jalankan: php artisan data:clean-dummy          (dengan konfirmasi)
 *           php artisan data:clean-dummy --dry-run (lihat dulu, tanpa hapus)
 */
class CleanDummyData extends Command
{
    protected $signature = 'data:clean-dummy {--dry-run : Tampilkan yang akan dihapus tanpa menghapus}';
    protected $description = 'Hapus user & pembayaran dummy (@example.com) sebelum production';

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');

        // Target: user dengan email dummy. Sesuaikan bila perlu.
        $dummyUsers = User::where('email', 'like', '%@example.com')->get();

        if ($dummyUsers->isEmpty()) {
            $this->info('Tidak ada user dummy (@example.com). Bersih.');
            return self::SUCCESS;
        }

        $this->warn('User dummy yang ditemukan:');
        $this->table(
            ['ID', 'Nama', 'Email'],
            $dummyUsers->map(fn ($u) => [$u->id, $u->name, $u->email])->toArray()
        );

        if ($dryRun) {
            $this->info('[dry-run] Tidak ada yang dihapus.');
            return self::SUCCESS;
        }

        if (!$this->confirm('Hapus user di atas beserta booking & pembayarannya?')) {
            $this->info('Dibatalkan.');
            return self::SUCCESS;
        }

        DB::transaction(function () use ($dummyUsers) {
            foreach ($dummyUsers as $user) {
                // Hapus pembayaran yang menempel pada booking milik user ini.
                foreach (['travelBookings', 'tourBookings'] as $relation) {
                    if (method_exists($user, $relation)) {
                        foreach ($user->{$relation} as $booking) {
                            Payment::where('payable_type', get_class($booking))
                                ->where('payable_id', $booking->id)
                                ->delete();
                            $booking->delete();
                        }
                    }
                }

                // Flight bookings (punya user_id langsung).
                \App\Models\FlightBooking::where('user_id', $user->id)->each(function ($fb) {
                    Payment::where('payable_type', \App\Models\FlightBooking::class)
                        ->where('payable_id', $fb->id)->delete();
                    $fb->delete();
                });

                $user->delete();
            }
        });

        $this->info('Selesai. Data dummy telah dihapus.');
        return self::SUCCESS;
    }
}
