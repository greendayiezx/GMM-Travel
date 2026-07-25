<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;

/**
 * PackageCatalog — sumber kebenaran harga paket wisata di backend.
 */
class PackageCatalog extends Model
{
    use HasUuid;

    protected $fillable = [
        'name',
        'base_price',
        'price_categories',
        'single_supplement',
        'duration',
        'max_pax',
        'active',
    ];

    protected $casts = [
        'price_categories'  => 'array',
        'base_price'        => 'integer',
        'single_supplement' => 'integer',
        'max_pax'           => 'integer',
        'active'            => 'boolean',
    ];
}
