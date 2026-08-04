<?php

namespace App\Http\Controllers;

use App\Mail\WelcomeMail;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;
use SendGrid\Mail\Mail as SendGridMail;

class ClerkWebhookController extends Controller
{
    /**
     * Handle Clerk webhook events.
     * Configure this endpoint in Clerk Dashboard → Webhooks.
     * Subscribe to: user.created
     */
    public function handle(Request $request): JsonResponse
    {
        // Verify Svix webhook signature
        $webhookSecret = config('services.clerk.webhook_secret');
        if ($webhookSecret && !$this->verifySignature($request, $webhookSecret)) {
            return response()->json(['error' => 'Invalid signature'], 401);
        }

        $payload = $request->json()->all();
        $type    = $payload['type'] ?? null;

        match ($type) {
            'user.created' => $this->handleUserCreated($payload['data'] ?? []),
            'email.created' => $this->handleEmailCreated($payload['data'] ?? []),
            default        => null,
        };

        return response()->json(['ok' => true]);
    }

    private function handleUserCreated(array $data): void
    {
        $email = $data['email_addresses'][0]['email_address'] ?? null;
        if (!$email) return;

        $firstName = $data['first_name'] ?? 'Pengguna';
        if (empty(trim($firstName))) $firstName = 'Pengguna';

        // Detect provider (Google OAuth sets external_accounts)
        $provider = 'email';
        if (!empty($data['external_accounts'])) {
            $provider = $data['external_accounts'][0]['provider'] ?? 'google';
        }

        // ── Buat/tautkan User lokal ──────────────────────────────
        // Ini WAJIB agar VerifyClerkToken bisa memetakan token Clerk ke user
        // lokal (lewat clerk_id). Tanpa record ini, user tidak akan bisa
        // mengakses endpoint yang butuh identitas terverifikasi.
        try {
            $clerkId  = $data['id'] ?? null;
            $lastName = $data['last_name'] ?? '';
            $fullName = trim($firstName . ' ' . $lastName) ?: 'Pengguna';

            if ($clerkId) {
                $userRole = Role::where('slug', 'user')->first();

                User::updateOrCreate(
                    ['clerk_id' => $clerkId],
                    [
                        'role_id' => $userRole?->id,
                        'name'    => $fullName,
                        'email'   => $email,
                        'avatar'  => $data['image_url'] ?? null,
                        // password dibiarkan null — user login lewat Clerk.
                    ]
                );
            }
        } catch (\Throwable $e) {
            Log::error('Failed to create local user from Clerk', ['error' => $e->getMessage()]);
        }

        try {
            Mail::to($email)->send(new WelcomeMail($firstName, $email, $provider));
            Log::info('Welcome email sent', ['email' => $email, 'provider' => $provider]);
        } catch (\Throwable $e) {
            Log::error('Failed to send welcome email', ['email' => $email, 'error' => $e->getMessage()]);
        }
    }

    private function handleEmailCreated(array $data): void
    {
        $to = $data['to_email_address'] ?? null;
        $subject = $data['subject'] ?? 'Verification';
        $body = $data['body'] ?? '';

        if ($to) {
            try {
                $this->sendEmailViaSendGrid($to, $subject, $body);
                Log::info('Email sent via SendGrid from Clerk webhook', ['email' => $to]);
            } catch (\Throwable $e) {
                Log::error('Failed to send email via SendGrid', ['email' => $to, 'error' => $e->getMessage()]);
            }
        }
    }

    private function sendEmailViaSendGrid(string $to, string $subject, string $body): void
    {
        $apiKey = env('SENDGRID_API_KEY');
        $fromEmail = env('SENDGRID_FROM_EMAIL', 'globalexplore29@gmail.com');

        $email = new SendGridMail();
        $email->setFrom($fromEmail);
        $email->setSubject($subject);
        $email->addTo($to);
        $email->addContent('text/html', $body);

        $sendgrid = new \SendGrid($apiKey);
        $sendgrid->send($email);
    }

    /**
     * Verify Svix webhook signature sent by Clerk.
     * Clerk uses the Svix library; the signing secret starts with "whsec_".
     */
    private function verifySignature(Request $request, string $secret): bool
    {
        $msgId        = $request->header('svix-id');
        $msgTimestamp = $request->header('svix-timestamp');
        $msgSignature = $request->header('svix-signature');

        if (!$msgId || !$msgTimestamp || !$msgSignature) return false;

        $toSign    = "{$msgId}.{$msgTimestamp}." . $request->getContent();
        $secretKey = base64_decode(substr($secret, strlen('whsec_')));
        $computed  = 'v1,' . base64_encode(hash_hmac('sha256', $toSign, $secretKey, true));

        // svix-signature may contain multiple space-separated signatures
        foreach (explode(' ', $msgSignature) as $sig) {
            if (hash_equals($sig, $computed)) return true;
        }
        return false;
    }
}
