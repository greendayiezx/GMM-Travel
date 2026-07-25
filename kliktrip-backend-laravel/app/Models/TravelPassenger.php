<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TravelPassenger extends Model
{
    use HasUuid;

    protected $fillable = ['travel_booking_id', 'name', 'seat_number', 'identity_number'];

    public function travelBooking(): BelongsTo
    {
        return $this->belongsTo(TravelBooking::class);
    }
}
