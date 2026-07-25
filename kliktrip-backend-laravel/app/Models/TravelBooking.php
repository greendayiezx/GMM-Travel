<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class TravelBooking extends Model
{
    use HasUuid, SoftDeletes;

    protected $fillable = [
        'user_id',
        'travel_schedule_id',
        'booking_code',
        'total_amount',
        'status',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function travelSchedule(): BelongsTo
    {
        return $this->belongsTo(TravelSchedule::class);
    }

    public function travelPassengers(): HasMany
    {
        return $this->hasMany(TravelPassenger::class);
    }

    public function payment(): MorphOne
    {
        return $this->morphOne(Payment::class, 'payable');
    }

    public function voucherUsages(): MorphMany
    {
        return $this->morphMany(VoucherUsage::class, 'usable');
    }
}
