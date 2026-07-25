<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TourParticipant extends Model
{
    use HasUuid;

    protected $fillable = ['tour_booking_id', 'name', 'identity_number', 'phone'];

    public function tourBooking(): BelongsTo
    {
        return $this->belongsTo(TourBooking::class);
    }
}
