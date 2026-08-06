# GMM Travel.id (Kliktrip)

**GMM Global Explore** adalah platform travel & tour yang menyediakan pemesanan tiket pesawat, travel shuttle antar kota, paket wisata, dan layanan umroh. Repositori ini adalah monorepo yang berisi backend API, aplikasi web, dan aplikasi mobile.

## Struktur Proyek

```
GMM Travle.id/
├── kliktrip-backend-laravel/   # REST API (Laravel 11 + PHP 8.2)
├── kliktrip-premium/           # Website utama (Angular 17)
├── kliktrip_mobile/            # Aplikasi mobile (Flutter)
└── docs/                       # Dokumentasi skema fitur (promo, loyalitas, dll)
```

### 1. `kliktrip-backend-laravel/` — Backend API

Laravel 11 REST API yang melayani seluruh data booking, user, promo, dan pembayaran.

- **Bahasa/Framework:** PHP 8.2, Laravel 11
- **Database:** PostgreSQL (Supabase)
- **Integrasi:** Midtrans (pembayaran), Resend & SendGrid (email)
- **Deploy:** Docker (Render) / Railway (`nixpacks.toml`, `railway.json`)

Setup lokal:
```bash
cd kliktrip-backend-laravel
composer install
cp .env.production.example .env   # sesuaikan kredensial database & API key
php artisan key:generate
php artisan migrate
php artisan serve
```

### 2. `kliktrip-premium/` — Website Utama

Website publik GMM Global Explore (pencarian tiket, travel shuttle, paket tour, umroh) dibangun dengan Angular 17.

Setup lokal:
```bash
cd kliktrip-premium
npm install
npm start   # ng serve, buka http://localhost:4200
```

### 3. `kliktrip_mobile/` — Aplikasi Mobile

Aplikasi mobile Flutter untuk pelanggan (pencarian & pemesanan tiket, shuttle, wisata, promo).

- **Arsitektur:** Clean Architecture (data / domain / presentation) dengan BLoC untuk state management dan `get_it` untuk dependency injection
- **Networking:** Dio
- **Auth:** Clerk

Setup lokal:
```bash
cd kliktrip_mobile
flutter pub get
flutter run
```

## Dokumentasi Tambahan

Skema fitur (promo/diskon, loyalitas & membership) ada di [`docs/`](docs/).

## Kontribusi

1. Buat branch baru dari `main`.
2. Commit dengan pesan yang jelas dan deskriptif.
3. Buka pull request ke `main`.
