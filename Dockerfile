# ============================================================
# Stage 1: Install backend dependencies with Composer
# ============================================================
FROM composer:2.8 AS vendor
WORKDIR /app

# Copy manifests first to leverage Docker cache
COPY composer.json composer.lock ./

# Install PHP dependencies (skip scripts to avoid artisan error)
RUN composer install --no-interaction --no-dev --no-scripts --prefer-dist --optimize-autoloader


# ============================================================
# Stage 2: Final application image
# ============================================================
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www

# Install PHP extensions, Node.js, npm, and build dependencies
RUN apk add --no-cache \
        php83-pdo_mysql \
        php83-pdo_pgsql \
        php83-zip \
        php83-bcmath \
        php83-tokenizer \
        php83-xml \
        php83-curl \
        php83-redis \
        nodejs \
        npm \
        $PHPIZE_DEPS \
        libpq-dev \
        libzip-dev

# ------------------------------------------------------------
# Copy the full application code
# ------------------------------------------------------------
COPY . /var/www/

# Copy vendor directory from Composer stage
COPY --from=vendor /app/vendor/ /var/www/vendor/

# ------------------------------------------------------------
# Build Frontend (Safe CI Mode)
# ------------------------------------------------------------
ENV WAYFINDER_SKIP_BUILD=1

# Disable php artisan calls from vite-plugin-wayfinder
RUN mv /usr/local/bin/php /usr/local/bin/php-real && \
    echo -e '#!/bin/sh\nif [ "$1" = "artisan" ]; then echo "Skipping artisan command during build"; else exec /usr/local/bin/php-real "$@"; fi' > /usr/local/bin/php && \
    chmod +x /usr/local/bin/php

# Install and build frontend safely
RUN npm ci && npm run build:ci

# Restore original PHP binary (optional)
RUN mv /usr/local/bin/php-real /usr/local/bin/php

# ------------------------------------------------------------
# Set permissions for Laravel writable directories
# ------------------------------------------------------------
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# ------------------------------------------------------------
# Expose PHP-FPM port
# ------------------------------------------------------------
EXPOSE 9000
CMD ["php-fpm"]
