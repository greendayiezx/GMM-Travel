<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

class PaymentMethod extends Model
{
    use HasUuid;

    protected $fillable = ['name', 'code', 'gateway', 'logo', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
