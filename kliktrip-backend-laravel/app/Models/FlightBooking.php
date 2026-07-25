<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;

class FlightBooking extends Model
{
    protected $fillable = [
        'user_id',
        'booking_code',
        'flight_data',
        'total_amount',
        'status',
    ];

    protected $casts = [
        'flight_data' => 'array',
        'total_amount' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function flightPassengers(): HasMany
    {
        return $this->hasMany(FlightPassenger::class);
    }

    public function flightTicketFiles(): HasMany
    {
        return $this->hasMany(FlightTicketFile::class);
    }

    public function payment(): MorphOne
    {
        return $this->morphOne(Payment::class, 'payable');
    }
}
