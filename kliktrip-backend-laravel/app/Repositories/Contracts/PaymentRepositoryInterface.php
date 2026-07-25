<?php

namespace App\Repositories\Contracts;

use App\Models\Payment;

interface PaymentRepositoryInterface extends BaseRepositoryInterface
{
    public function findByInvoiceNumber(string $invoiceNumber): ?Payment;

    public function updatePaymentStatus(string $invoiceNumber, string $status): bool;
}
