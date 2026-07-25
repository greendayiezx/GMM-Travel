<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Payment extends Model
{
    use HasUuid;

    protected $fillable = [
        'payable_id',
        'payable_type',
        'invoice_number',
        'gateway',
        'gateway_transaction_id',
        'snap_token',
        'payment_instructions',
        'payment_method',
        'gross_amount',
        'admin_fee',
        'discount',
        'total_amount',
        'status',
        'paid_at',
        'expired_at',
    ];

    protected $casts = [
        'payment_instructions' => 'array',
        'gross_amount' => 'decimal:2',
        'admin_fee' => 'decimal:2',
        'discount' => 'decimal:2',
        'total_amount' => 'decimal:2',
        'paid_at' => 'datetime',
        'expired_at' => 'datetime',
    ];

    public function payable(): MorphTo
    {
        return $this->morphTo();
    }

    public function paymentLogs(): HasMany
    {
        return $this->hasMany(PaymentLog::class);
    }
}
