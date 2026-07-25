<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TravelRoute extends Model
{
    use HasUuid;

    protected $fillable = ['departure_city_id', 'arrival_city_id', 'distance_km', 'duration_minutes'];

    protected $casts = [
        'distance_km' => 'integer',
        'duration_minutes' => 'integer',
    ];

    public function departureCity(): BelongsTo
    {
        return $this->belongsTo(City::class, 'departure_city_id');
    }

    public function arrivalCity(): BelongsTo
    {
        return $this->belongsTo(City::class, 'arrival_city_id');
    }

    public function travelSchedules(): HasMany
    {
        return $this->hasMany(TravelSchedule::class);
    }
}
