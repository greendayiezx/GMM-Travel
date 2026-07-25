<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehicle extends Model
{
    use HasUuid;

    protected $fillable = ['name', 'license_plate', 'type', 'capacity', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
        'capacity' => 'integer',
    ];

    public function travelSchedules(): HasMany
    {
        return $this->hasMany(TravelSchedule::class);
    }
}
