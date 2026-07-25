<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class VoucherUsage extends Model
{
    use HasUuid;

    protected $fillable = ['voucher_id', 'user_id', 'usable_id', 'usable_type'];

    public function voucher(): BelongsTo
    {
        return $this->belongsTo(Voucher::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function usable(): MorphTo
    {
        return $this->morphTo();
    }
}
