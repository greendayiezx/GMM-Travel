<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TourCategory extends Model
{
    use HasUuid;

    protected $fillable = ['name', 'slug'];

    public function tourPackages(): HasMany
    {
        return $this->hasMany(TourPackage::class);
    }
}
