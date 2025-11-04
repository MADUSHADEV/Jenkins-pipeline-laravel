# ============================================================
# Stage 1: Composer (Backend Dependencies)
# ============================================================
FROM composer:2.8 AS vendor
WORKDIR /app

# Copy only composer files first (for better caching)
COPY composer.json composer.lock ./

# Install dependencies without dev and without running scripts
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader \
    && rm -rf bootstrap/cache/*.php

# Copy full application code (needed for autoload dump)
COPY . .

# Rebuild optimized autoloader cleanly (now artisan is available)
RUN composer dump-autoload --optimize


# ============================================================
# Stage 2: Node (Frontend Build)
# ============================================================
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Copy app source and build frontend assets
COPY . .
# Disable Laravel Wayfinder artisan calls during build
ENV WAYFINDER_SKIP_BUILD=1

RUN npm run build


# ============================================================
# Stage 3: PHP-FPM (Final Production Image)
# ============================================================
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www

# --- System and PHP extensions ---
RUN apk add --no-cache \
        php83-pdo_mysql \
        php83-pdo_pgsql \
        php83-bcmath \
        php83-zip \
        php83-tokenizer \
        php83-xml \
        php83-curl \
        php83-redis \
        libpq-dev \
        libzip-dev \
        bash shadow supervisor

# --- Copy backend code and vendor ---
COPY --from=vendor /app /var/www
COPY --from=vendor /app/vendor /var/www/vendor

# --- Copy built frontend assets ---
COPY --from=frontend /app/public /var/www/public

# --- Laravel optimization ---
RUN php artisan config:clear || true \
    && php artisan cache:clear || true \
    && php artisan route:clear || true \
    && php artisan view:clear || true \
    && php artisan optimize || true

# --- Set correct permissions for writable dirs ---
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# --- Expose PHP-FPM port ---
EXPOSE 9000

# --- Start PHP-FPM ---
CMD ["php-fpm"]
