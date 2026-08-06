<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('promo_claims', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignUuid('tour_catalog_id')->constrained('tour_catalogs')->onDelete('cascade');
            $table->timestamp('claimed_at');
            $table->timestamps();

            $table->unique(['user_id', 'tour_catalog_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('promo_claims');
    }
};
