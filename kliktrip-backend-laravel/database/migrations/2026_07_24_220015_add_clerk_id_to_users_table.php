<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menambah kolom clerk_id ke tabel users.
 *
 * clerk_id menautkan identitas user di Clerk (klaim `sub` pada JWT) ke record
 * User lokal. Middleware VerifyClerkToken memakainya untuk menemukan user yang
 * identitasnya sudah diverifikasi secara kriptografis — bukan sekadar klaim
 * dari frontend.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Nullable karena user lama (kalau ada) belum punya clerk_id.
            // Unique agar satu akun Clerk = satu user lokal.
            $table->string('clerk_id')->nullable()->unique()->after('id');

            // Password kini opsional: user yang daftar via Google OAuth tidak
            // punya password lokal.
            $table->string('password')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['clerk_id']);
            $table->dropColumn('clerk_id');
        });
    }
};
