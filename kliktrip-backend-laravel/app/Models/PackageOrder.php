<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphOne;

/**
 * PackageOrder — order paket wisata yang dipersist ke DB.
 * Memungkinkan proteksi order hash + cek kepemilikan pada flow paket.
 */
class PackageOrder extends Model
{
    use HasUuid;

    protected $fillable = [
        'order_code',
        'user_id',
        'package_name',
        'total_amount',
        'items',
        'status',
    ];

    protected $casts = [
        'items'        => 'array',
        'total_amount' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function payment(): MorphOne
    {
        return $this->morphOne(Payment::class, 'payable');
    }
}
