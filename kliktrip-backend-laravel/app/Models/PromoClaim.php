<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PromoClaim extends Model
{
    use HasUuid;

    protected $fillable = ['user_id', 'tour_catalog_id', 'claimed_at'];

    protected $casts = [
        'claimed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tourCatalog(): BelongsTo
    {
        return $this->belongsTo(TourCatalog::class);
    }
}
