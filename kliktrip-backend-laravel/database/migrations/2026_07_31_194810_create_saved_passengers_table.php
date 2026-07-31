<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('saved_passengers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->string('full_name');
            $table->string('category')->default('Dewasa');
            $table->string('identity_number');
            $table->string('passport_number')->nullable();
            $table->string('gender')->default('Laki-laki');
            $table->string('birth_date')->nullable();
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'full_name']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('saved_passengers');
    }
};
