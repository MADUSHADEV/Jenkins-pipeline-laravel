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
# Stage 2: Frontend Build (PHP + Node)
# ============================================================
# Changed base to PHP-Alpine (provides php binary)
FROM php:8.3-alpine AS frontend
WORKDIR /app
# Install Node.js and npm (added for frontend build)
RUN apk add --no-cache nodejs npm
# Install PHP extensions if needed for build (e.g., if artisan or plugins require them)
RUN apk add --no-cache \
        $PHPIZE_DEPS \
        libpq-dev \
        libzip-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        oniguruma-dev \
    && docker-php-ext-install pdo_mysql pdo_pgsql zip bcmath xml curl tokenizer \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS
COPY package.json package-lock.json ./
RUN npm ci
# Copy app source and build frontend assets
COPY . .
ENV WAYFINDER_SKIP_BUILD=1
# Disable php artisan calls from vite-plugin-wayfinder
RUN mv /usr/local/bin/php /usr/local/bin/php-real && \
    echo -e '#!/bin/sh\nif [ "$1" = "artisan" ]; then echo "Skipping artisan command during build"; else exec /usr/local/bin/php-real "$@"; fi' > /usr/local/bin/php && \
    chmod +x /usr/local/bin/php
# Install and build frontend safely
RUN npm ci && npm run build:ci
# Restore original PHP binary (uncommented and required to avoid issues if other build steps need real php)
RUN mv /usr/local/bin/php-real /usr/local/bin/php

# ============================================================
# Stage 3: PHP-FPM (Final Production Image)
# ============================================================
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www
# --- System and PHP extensions (switched to docker-php-ext for consistency) ---
RUN apk add --no-cache \
        $PHPIZE_DEPS \
        libpq-dev \
        libzip-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        oniguruma-dev \
        bash shadow supervisor \
    && docker-php-ext-install pdo_mysql pdo_pgsql zip bcmath xml curl tokenizer \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS
# --- Copy backend code and vendor ---
COPY --from=vendor /app /var/www
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