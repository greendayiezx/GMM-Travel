<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_images', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tour_package_id')->constrained('tour_packages')->onDelete('cascade');
            $table->string('image_path');
            $table->boolean('is_primary')->default(false);
            $table->timestamps();

            $table->index('tour_package_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_images');
    }
};
