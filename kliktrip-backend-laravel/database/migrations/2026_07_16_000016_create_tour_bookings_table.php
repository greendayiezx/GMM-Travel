<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_bookings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignUuid('tour_schedule_id')->constrained('tour_schedules')->onDelete('cascade');
            $table->string('booking_code')->unique();
            $table->integer('total_participants');
            $table->decimal('total_amount', 12, 2);
            $table->enum('status', ['PENDING', 'CONFIRMED', 'PAID', 'EXPIRED', 'CANCELLED'])->default('PENDING');
            $table->softDeletes();
            $table->timestamps();

            $table->index('user_id');
            $table->index('tour_schedule_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_bookings');
    }
};
