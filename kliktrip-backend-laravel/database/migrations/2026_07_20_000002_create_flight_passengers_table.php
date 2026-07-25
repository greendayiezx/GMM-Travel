<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('flight_passengers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('flight_booking_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->string('full_name');
            $table->date('date_of_birth');
            $table->string('id_type');
            $table->string('id_number');
            $table->string('phone');
            $table->string('email');
            $table->string('passenger_type');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('flight_passengers');
    }
};
