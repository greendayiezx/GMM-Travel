<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/**
 * Dikirim SINKRON (tanpa ShouldQueue) — sama seperti WelcomeMail. Railway
 * tidak menjalankan queue worker, jadi kalau di-queue email tidak akan
 * pernah terkirim.
 */
class DataExportMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly string $name,
        public readonly string $email,
        public readonly array $data,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Salinan Data Pribadi Anda — GMM Global Explore',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.data_export',
            text: 'emails.data_export_text',
        );
    }
}
