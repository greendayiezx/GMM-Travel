<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Perbaiki flight_bookings.user_id: semula `unsignedBigInteger` (salah), padahal
 * users.id adalah UUID. Di MySQL perbandingan bigint = uuid diam-diam lolos
 * (hasil kosong), tapi Postgres (Supabase) menolak → error 500 di /me/stats.
 * Tabel masih kosong sehingga aman drop & buat ulang kolomnya sebagai uuid.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('flight_bookings', function (Blueprint $table) {
            $table->dropColumn('user_id');
        });
        Schema::table('flight_bookings', function (Blueprint $table) {
            $table->uuid('user_id')->nullable()->index();
        });
    }

    public function down(): void
    {
        Schema::table('flight_bookings', function (Blueprint $table) {
            $table->dropColumn('user_id');
        });
        Schema::table('flight_bookings', function (Blueprint $table) {
            $table->unsignedBigInteger('user_id')->nullable();
        });
    }
};
