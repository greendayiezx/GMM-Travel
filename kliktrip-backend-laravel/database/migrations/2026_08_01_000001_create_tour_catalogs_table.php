<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * tour_catalogs
 * -------------
 * Katalog paket wisata (dipindah dari asset lokal mobile `wisata.json` ke backend).
 * Menyimpan seluruh objek paket sebagai JSON `payload` agar bentuknya persis
 * dengan model WisataPackage di mobile. Tanggal keberangkatan TIDAK disimpan di
 * sini — di-generate saat request (endpoint /tours) supaya selalu future.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tour_catalogs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('external_id')->unique();   // id dari wisata.json
            $table->string('kategori')->index();        // IBADAH | INTERNASIONAL | DOMESTIK | EVENT
            $table->string('nama_paket');
            $table->json('payload');                    // objek paket lengkap
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tour_catalogs');
    }
};
