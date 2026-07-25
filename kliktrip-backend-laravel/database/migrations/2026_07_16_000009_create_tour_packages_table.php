<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_packages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('tour_category_id')->constrained('tour_categories')->onDelete('cascade');
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description');
            $table->string('meeting_point');
            $table->text('includes');
            $table->text('excludes');
            $table->text('terms');
            $table->string('thumbnail');
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index('tour_category_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_packages');
    }
};
