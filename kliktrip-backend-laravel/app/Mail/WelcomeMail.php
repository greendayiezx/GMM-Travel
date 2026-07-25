<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Dikirim SINKRON (tanpa ShouldQueue). Railway tidak menjalankan queue worker,
 * jadi kalau di-queue email tidak akan pernah terkirim. Resend memakai HTTP API
 * yang cepat, jadi mengirim langsung di dalam request webhook aman.
 */
class WelcomeMail extends Mailable
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
        // Sertakan versi teks (multipart) — meningkatkan deliverability &
        // mengurangi kemungkinan masuk spam dibanding HTML-only.
        return new Content(
            view: 'emails.welcome',
            text: 'emails.welcome_text',
        );
    }
}
