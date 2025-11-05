# ============================================================
# Stage 1: Composer (Backend Dependencies)
# ============================================================
FROM composer:2.8 AS vendor
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

COPY . .
RUN composer dump-autoload --optimize


# ============================================================
# Stage 2: Node (Frontend Build)
# ============================================================
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Copy source
COPY . .

# --- Add fake PHP binary to bypass artisan commands during frontend build ---
RUN echo '#!/bin/sh' > /usr/local/bin/php && \
    echo 'echo "Fake PHP: skipping artisan commands"' >> /usr/local/bin/php && \
    chmod +x /usr/local/bin/php

# --- Run frontend build ---
RUN npm run build:ci || npm run build


# ============================================================
# Stage 3: PHP-FPM (Final Production Image)
# ============================================================
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www

# --- Install system dependencies & PHP extensions ---
RUN apk add --no-cache \
    libpq-dev \
    libzip-dev \
    sqlite \
    zip unzip \
    bash shadow supervisor \
    autoconf g++ make linux-headers \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql bcmath opcache \
    && apk del autoconf g++ make linux-headers

# --- Install Redis extension via PECL ---
RUN pecl install redis && docker-php-ext-enable redis

# --- Copy built app files ---
COPY --from=vendor /app /var/www
COPY --from=vendor /app/vendor /var/www/vendor
COPY --from=frontend /app/public /var/www/public

# --- Clear and optimize Laravel caches ---
RUN php artisan config:clear || true \
 && php artisan cache:clear || true \
 && php artisan route:clear || true \
 && php artisan view:clear || true \
 && php artisan optimize || true

# --- Permissions ---
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
 && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# --- Expose PHP-FPM port ---
EXPOSE 9000

CMD ["php-fpm"]
