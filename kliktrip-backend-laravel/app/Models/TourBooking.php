<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class TourBooking extends Model
{
    use HasUuid, SoftDeletes;

    protected $fillable = [
        'user_id',
        'tour_schedule_id',
        'booking_code',
        'total_participants',
        'total_amount',
        'status',
    ];

    protected $casts = [
        'total_participants' => 'integer',
        'total_amount' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tourSchedule(): BelongsTo
    {
        return $this->belongsTo(TourSchedule::class);
    }

    public function tourParticipants(): HasMany
    {
        return $this->hasMany(TourParticipant::class);
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
