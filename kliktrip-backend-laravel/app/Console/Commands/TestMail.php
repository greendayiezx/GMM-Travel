<?php

namespace App\Console\Commands;

use App\Mail\WelcomeMail;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

/**
 * Kirim email test SINKRON (tidak lewat antrean) untuk mendiagnosis SMTP.
 * Menampilkan konfigurasi mail aktif + error SMTP persis bila gagal.
 *
 *   php artisan mail:test tujuan@email.com
 */
class TestMail extends Command
{
    protected $signature = 'mail:test {to}';
    protected $description = 'Kirim email test sinkron untuk cek koneksi SMTP';

    public function handle(): int
    {
        $to = $this->argument('to');

        // Tampilkan config mail yang benar-benar dipakai (dari config cache).
        $this->info('Konfigurasi mail aktif:');
        $this->line('  MAILER    : ' . config('mail.default'));
        $this->line('  HOST      : ' . config('mail.mailers.smtp.host'));
        $this->line('  PORT      : ' . config('mail.mailers.smtp.port'));
        $this->line('  ENCRYPTION: ' . (config('mail.mailers.smtp.encryption') ?? '(kosong)'));
        $this->line('  USERNAME  : ' . config('mail.mailers.smtp.username'));
        $this->line('  FROM      : ' . config('mail.from.address'));
        $this->newLine();

        $this->info("Mengirim email WELCOME asli ke {$to} ...");

        try {
            // Kirim WelcomeMail persis seperti alur registrasi (render template
            // emails.welcome) agar error rendering/kirim muncul di sini.
            Mail::to($to)->send(new WelcomeMail('Test', $to, 'email'));
            $this->info('BERHASIL: welcome email terkirim tanpa error.');
            $this->line('Cek inbox & folder Spam di ' . $to);
            return self::SUCCESS;
        } catch (\Throwable $e) {
            $this->error('GAGAL kirim welcome email:');
            $this->error($e->getMessage());
            $this->line('File: ' . $e->getFile() . ':' . $e->getLine());
            return self::FAILURE;
        }
    }
}
