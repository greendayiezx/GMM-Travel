<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Driver extends Model
{
    use HasUuid;

    protected $fillable = ['name', 'phone', 'license_number', 'is_active'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function travelSchedules(): HasMany
    {
        return $this->hasMany(TravelSchedule::class);
    }
}
