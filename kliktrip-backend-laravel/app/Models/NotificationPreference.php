<?php

namespace App\Models;

use App\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Preferensi notifikasi milik user (halaman "App Settings" di app mobile).
 * Menentukan channel/tipe notifikasi yang ingin diterima user: push, promo
 * email, dan pembaruan pesanan. Default-nya sengaja disamakan dengan default
 * lokal di mobile (SettingsService) agar perilaku konsisten saat pertama
 * digunakan.
 */
class NotificationPreference extends Model
{
    use HasUuid;

    protected $fillable = [
        'user_id',
        'push_notifications',
        'email_promos',
        'order_updates',
    ];

    protected $casts = [
        'push_notifications' => 'boolean',
        'email_promos'       => 'boolean',
        'order_updates'      => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
