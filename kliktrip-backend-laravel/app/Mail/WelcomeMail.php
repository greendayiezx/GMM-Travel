<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * ShouldQueue: email dikirim lewat antrean (background), tidak memblokir
 * response webhook. Di production set QUEUE_CONNECTION=database/redis +
 * jalankan `php artisan queue:work`. Di local (QUEUE_CONNECTION=sync) tetap
 * terkirim langsung.
 */
class WelcomeMail extends Mailable implements ShouldQueue
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly string $firstName,
        public readonly string $email,
        public readonly string $provider = 'email', // 'google', 'email', dll
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Selamat datang di GMM Global Explore! 🌍',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.welcome',
        );
    }
}
