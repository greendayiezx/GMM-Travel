<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('travel_schedules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('vehicle_id')->constrained('vehicles')->onDelete('cascade');
            $table->foreignUuid('travel_route_id')->constrained('travel_routes')->onDelete('cascade');
            $table->foreignUuid('driver_id')->constrained('drivers')->onDelete('cascade');
            $table->dateTime('departure_time');
            $table->dateTime('arrival_time');
            $table->integer('available_seats');
            $table->decimal('price', 12, 2);
            $table->enum('status', ['SCHEDULED', 'ON_TRIP', 'ARRIVED', 'CANCELLED'])->default('SCHEDULED');
            $table->timestamps();

            $table->index('vehicle_id');
            $table->index('travel_route_id');
            $table->index('driver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('travel_schedules');
    }
};
