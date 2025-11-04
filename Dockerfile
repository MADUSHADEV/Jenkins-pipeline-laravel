# ============================================================
# Stage 1: Install backend dependencies with Composer
# ============================================================
FROM composer:2.8 AS vendor
WORKDIR /app

# Copy manifests first to leverage Docker cache
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader


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
# Copy the application code FIRST
# ------------------------------------------------------------
COPY . /var/www/

# Copy vendor directory from Composer stage
COPY --from=vendor /app/vendor/ /var/www/vendor/

# ------------------------------------------------------------
# Build Frontend (Safe CI Mode)
# ------------------------------------------------------------

# Mark this build as CI mode (so Wayfinder skips PHP artisan)
ENV WAYFINDER_SKIP_BUILD=1

# Run CI build script (defined in package.json)
RUN npm ci && npm run build:ci

# Optional cleanup (saves image size)
# RUN apk del nodejs npm

# ------------------------------------------------------------
# Set permissions for Laravel writable directories
# ------------------------------------------------------------
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# ------------------------------------------------------------
# Expose PHP-FPM port
# ------------------------------------------------------------
EXPOSE 9000
CMD ["php-fpm"]
