<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FlightTicketFile extends Model
{
    protected $fillable = [
        'flight_booking_id',
        'file_path',
        'original_name',
        'uploaded_by',
    ];

    public function flightBooking(): BelongsTo
    {
        return $this->belongsTo(FlightBooking::class);
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }
}
