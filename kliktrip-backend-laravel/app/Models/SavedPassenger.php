<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Data penumpang tersimpan milik user (dipakai halaman "Saved Passenger Data"
 * di app mobile). Terpisah dari TravelPassenger/FlightPassenger yang melekat
 * pada satu booking — ini daftar kontak penumpang reusable milik user.
 */
class SavedPassenger extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'title',
        'full_name',
        'category',
        'identity_number',
        'passport_number',
        'gender',
        'birth_date',
        'is_primary',
    ];

    protected $casts = [
        'is_primary' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
