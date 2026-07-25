<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('flight_bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('booking_code')->unique();
            $table->json('flight_data');
            $table->decimal('total_amount', 12, 2);
            $table->enum('status', [
                'PENDING',
                'PAID',
                'PROCESSING_ISSUANCE',
                'ISSUED',
                'FAILED_ISSUANCE',
                'EXPIRED',
                'CANCELLED',
            ])->default('PENDING');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('flight_bookings');
    }
};
