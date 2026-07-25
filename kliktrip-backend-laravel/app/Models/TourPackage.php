<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TourPackage extends Model
{
    use HasUuid;

    protected $fillable = [
        'tour_category_id',
        'name',
        'slug',
        'description',
        'meeting_point',
        'includes',
        'excludes',
        'terms',
        'thumbnail',
        'is_featured',
        'is_active',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function tourCategory(): BelongsTo
    {
        return $this->belongsTo(TourCategory::class);
    }

    public function tourImages(): HasMany
    {
        return $this->hasMany(TourImage::class);
    }

    public function tourItineraries(): HasMany
    {
        return $this->hasMany(TourItinerary::class);
    }

    public function tourSchedules(): HasMany
    {
        return $this->hasMany(TourSchedule::class);
    }
}
