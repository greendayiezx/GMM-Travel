<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('travel_passengers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('travel_booking_id')->constrained('travel_bookings')->onDelete('cascade');
            $table->string('name');
            $table->string('seat_number');
            $table->string('identity_number');
            $table->timestamps();

            $table->index('travel_booking_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('travel_passengers');
    }
};
