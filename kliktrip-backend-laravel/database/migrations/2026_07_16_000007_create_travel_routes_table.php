<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('travel_routes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('departure_city_id')->constrained('cities')->onDelete('cascade');
            $table->foreignUuid('arrival_city_id')->constrained('cities')->onDelete('cascade');
            $table->integer('distance_km');
            $table->integer('duration_minutes');
            $table->timestamps();

            $table->index('departure_city_id');
            $table->index('arrival_city_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('travel_routes');
    }
};
