<?php

namespace App\Services;

use App\Repositories\Contracts\PaymentRepositoryInterface;
use App\Models\Payment;
use App\Models\TravelBooking;
use App\Models\TourBooking;
use App\Models\FlightBooking;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Exception;

class PaymentService
{
    protected PaymentRepositoryInterface $paymentRepository;

    public function __construct(PaymentRepositoryInterface $paymentRepository)
    {
        $this->paymentRepository = $paymentRepository;
    }

    /**
     * Create payment invoice for travel or tour booking.
     */
    public function initiatePayment(string $payableId, string $payableType, string $paymentMethodCode): Payment
    {
        return DB::transaction(function () use ($payableId, $payableType, $paymentMethodCode) {
            // Retrieve booking
            $booking = match ($payableType) {
                'TRAVEL' => TravelBooking::findOrFail($payableId),
                'FLIGHT' => FlightBooking::findOrFail($payableId),
                default  => TourBooking::findOrFail($payableId),
            };

            $invoiceNumber = 'INV-' . date('Ymd') . '-' . strtoupper(Str::random(6));

            // Calculate fees (example logic)
            $adminFee = 5000.00;
            $discount = 0.00;
            $totalAmount = $booking->total_amount + $adminFee - $discount;

            // Generate snap token dummy for Midtrans/Xendit integration
            $snapToken = 'snap-tok-' . Str::uuid();

            // Create Payment record
            $payment = $this->paymentRepository->create([
                'payable_id' => $booking->id,
                'payable_type' => get_class($booking),
                'invoice_number' => $invoiceNumber,
                'gateway' => 'MIDTRANS',
                'gateway_transaction_id' => null,
                'snap_token' => $snapToken,
                'payment_method' => $paymentMethodCode,
                'gross_amount' => $booking->total_amount,
                'admin_fee' => $adminFee,
                'discount' => $discount,
                'total_amount' => $totalAmount,
                'status' => 'PENDING',
                'expired_at' => now()->addDay(),
            ]);

            return $payment;
        });
    }

    /**
     * Handle payment gateway webhook callback (Midtrans/Xendit).
     */
    public function processCallback(array $payload): bool
    {
        return DB::transaction(function () use ($payload) {
            $invoiceNumber = $payload['order_id'];
            $transactionStatus = $payload['transaction_status'];
            $gatewayTransactionId = $payload['transaction_id'];

            $payment = $this->paymentRepository->findByInvoiceNumber($invoiceNumber);

            if (!$payment) {
                throw new Exception("Invoice payment tidak ditemukan.");
            }

            // Create log
            $payment->paymentLogs()->create([
                'raw_payload' => $payload,
                'status' => $transactionStatus,
                'description' => "Callback received from Midtrans: status {$transactionStatus}",
            ]);

            // Update status based on Midtrans status mapping
            if ($transactionStatus === 'settlement' || $transactionStatus === 'capture') {
                $payment->status = 'SUCCESS';
                $payment->gateway_transaction_id = $gatewayTransactionId;
                $payment->paid_at = now();
                $payment->save();

                // Update booking status as PAID
                $booking = $payment->payable;
                $booking->status = 'PAID';
                $booking->save();

                return true;
            } elseif (in_array($transactionStatus, ['expire', 'cancel', 'deny'])) {
                $payment->status = 'EXPIRED';
                $payment->save();

                // Update booking status as EXPIRED
                $booking = $payment->payable;
                $booking->status = 'EXPIRED';
                $booking->save();

                return true;
            }

            return false;
        });
    }
}
