<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Queue tables (untuk QUEUE_CONNECTION=database di production) ──
        if (!Schema::hasTable('jobs')) {
            Schema::create('jobs', function (Blueprint $table) {
                $table->id();
                $table->string('queue')->index();
                $table->longText('payload');
                $table->unsignedTinyInteger('attempts');
                $table->unsignedInteger('reserved_at')->nullable();
                $table->unsignedInteger('available_at');
                $table->unsignedInteger('created_at');
            });
        }

        if (!Schema::hasTable('failed_jobs')) {
            Schema::create('failed_jobs', function (Blueprint $table) {
                $table->id();
                $table->string('uuid')->unique();
                $table->text('connection');
                $table->text('queue');
                $table->longText('payload');
                $table->longText('exception');
                $table->timestamp('failed_at')->useCurrent();
            });
        }

        // ── package_orders — persist order paket (sebelumnya tidak disimpan) ──
        // Kini setiap charge paket punya record order di DB, sehingga bisa
        // dilindungi order hash + cek kepemilikan (anti-IDOR), konsisten dengan
        // flow travel & flight.
        Schema::create('package_orders', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('order_code')->unique();          // orderId dari client
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('package_name');
            $table->unsignedBigInteger('total_amount');
            $table->json('items')->nullable();               // rincian tiket
            $table->string('status')->default('PENDING');    // PENDING/PAID/EXPIRED/CANCELLED
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_orders');
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('jobs');
    }
};
