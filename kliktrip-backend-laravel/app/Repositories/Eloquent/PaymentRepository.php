<?php

namespace App\Repositories\Eloquent;

use App\Models\Payment;
use App\Repositories\Contracts\PaymentRepositoryInterface;

class PaymentRepository extends BaseRepository implements PaymentRepositoryInterface
{
    public function __construct(Payment $model)
    {
        parent::__construct($model);
    }

    public function findByInvoiceNumber(string $invoiceNumber): ?Payment
    {
        return $this->model->where('invoice_number', $invoiceNumber)->first();
    }

    public function updatePaymentStatus(string $invoiceNumber, string $status): bool
    {
        $payment = $this->findByInvoiceNumber($invoiceNumber);
        if ($payment) {
            $payment->status = $status;
            if ($status === 'SUCCESS') {
                $payment->paid_at = now();
            }
            return $payment->save();
        }
        return false;
    }
}
