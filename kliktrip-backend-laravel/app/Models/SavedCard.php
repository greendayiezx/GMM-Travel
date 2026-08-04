<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Kartu pembayaran tersimpan milik user, direferensikan lewat token Midtrans
 * (saved_token_id) — nomor kartu mentah TIDAK PERNAH disimpan di sini karena
 * tokenisasi terjadi langsung di device (lihat MidtransCardRegisterDataSource
 * di app mobile).
 */
class SavedCard extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'gateway',
        'saved_token_id',
        'masked_card',
        'card_type',
        'bank',
        'is_default',
    ];

    protected $casts = [
        'is_default' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
