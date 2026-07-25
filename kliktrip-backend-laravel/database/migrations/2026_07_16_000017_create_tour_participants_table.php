<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_participants', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tour_booking_id')->constrained('tour_bookings')->onDelete('cascade');
            $table->string('name');
            $table->string('identity_number');
            $table->string('phone');
            $table->timestamps();

            $table->index('tour_booking_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_participants');
    }
};
