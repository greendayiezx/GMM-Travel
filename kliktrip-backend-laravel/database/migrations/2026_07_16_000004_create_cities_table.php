<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cities', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('province_id')->constrained('provinces')->onDelete('cascade');
            $table->string('name');
            $table->timestamps();

            $table->index('province_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cities');
    }
};
