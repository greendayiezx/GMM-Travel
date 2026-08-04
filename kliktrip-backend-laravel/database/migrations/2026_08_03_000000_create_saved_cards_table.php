<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('saved_cards', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained()->cascadeOnDelete();
            $table->string('gateway')->default('MIDTRANS');
            $table->string('saved_token_id');
            $table->string('masked_card');
            $table->string('card_type')->nullable();
            $table->string('bank')->nullable();
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
            $table->unique(['user_id', 'saved_token_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('saved_cards');
    }
};
