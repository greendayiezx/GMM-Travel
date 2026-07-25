<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_itineraries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tour_package_id')->constrained('tour_packages')->onDelete('cascade');
            $table->integer('day');
            $table->string('title');
            $table->text('description');
            $table->string('activity_time')->nullable();
            $table->timestamps();

            $table->index('tour_package_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_itineraries');
    }
};
