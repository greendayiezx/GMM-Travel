<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'invoice_number' => $this->invoice_number,
            'gateway' => $this->gateway,
            'payment_method' => $this->payment_method,
            'snap_token' => $this->snap_token,
            'payment_instructions' => $this->payment_instructions,
            'gross_amount' => (float) $this->gross_amount,
            'admin_fee' => (float) $this->admin_fee,
            'discount' => (float) $this->discount,
            'total_amount' => (float) $this->total_amount,
            'status' => $this->status,
            'paid_at' => $this->paid_at?->toIso8601String(),
            'expired_at' => $this->expired_at?->toIso8601String(),
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
