<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel package_catalogs — SUMBER KEBENARAN harga paket wisata.
 *
 * Sebelumnya harga paket hanya ada sebagai konstanta statis di frontend,
 * sehingga backend tidak bisa memvalidasi `amount` yang dikirim client
 * (celah price manipulation). Tabel ini memindahkan harga ke server agar
 * total pembayaran bisa dihitung & diverifikasi di backend.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('package_catalogs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name')->unique();          // key paket (sama dgn PACKAGES di frontend)
            $table->unsignedBigInteger('base_price');  // harga dasar per pax (rupiah)
            $table->json('price_categories')->nullable(); // [{type, price}] untuk paket berkategori
            $table->unsignedBigInteger('single_supplement')->nullable();
            $table->string('duration')->nullable();
            $table->unsignedInteger('max_pax')->nullable();
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_catalogs');
    }
};
