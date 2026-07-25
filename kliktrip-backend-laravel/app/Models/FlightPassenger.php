<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FlightPassenger extends Model
{
    protected $fillable = [
        'flight_booking_id',
        'title',
        'full_name',
        'date_of_birth',
        'id_type',
        'id_number',
        'phone',
        'email',
        'passenger_type',
    ];

    protected $casts = [
        'date_of_birth' => 'date',
    ];

    public function flightBooking(): BelongsTo
    {
        return $this->belongsTo(FlightBooking::class);
    }
}
