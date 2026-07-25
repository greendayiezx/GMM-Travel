<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_schedules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tour_package_id')->constrained('tour_packages')->onDelete('cascade');
            $table->date('departure_date');
            $table->date('return_date');
            $table->integer('available_slots');
            $table->decimal('price', 12, 2);
            $table->enum('status', ['SCHEDULED', 'ACTIVE', 'COMPLETED', 'CANCELLED'])->default('SCHEDULED');
            $table->timestamps();

            $table->index('tour_package_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_schedules');
    }
};
