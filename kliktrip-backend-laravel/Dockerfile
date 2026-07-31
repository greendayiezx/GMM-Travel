# Dockerfile untuk deploy Laravel ke Render (host) + Supabase (DB Postgres).
# Render tidak punya runtime PHP native, jadi wajib pakai Docker.
FROM php:8.2-cli

# Dependency sistem + ekstensi PHP (termasuk pdo_pgsql untuk Supabase Postgres).
RUN apt-get update && apt-get install -y \
        git unzip libpq-dev libzip-dev libpng-dev libonig-dev \
    && docker-php-ext-install pdo_pgsql mbstring bcmath zip gd \
    && rm -rf /var/lib/apt/lists/*

# Composer (disalin dari image resmi).
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . /app

# Install dependency PHP (production) + siapkan folder cache/storage.
RUN composer install --no-dev --optimize-autoloader --no-interaction \
    && mkdir -p storage/framework/views storage/framework/cache/data \
                storage/framework/sessions bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Render menyuntik $PORT saat runtime (default 10000).
ENV PORT=10000
EXPOSE 10000

# Jalankan migrate (non-blocking) lalu serve. Migrasi yang gagal tidak
# menghentikan server, agar endpoint tetap hidup.
CMD sh -c "php artisan migrate --force || true; \
           php artisan serve --host=0.0.0.0 --port=${PORT}"
