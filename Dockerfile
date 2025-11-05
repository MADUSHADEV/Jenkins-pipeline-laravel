# ============================================================
# Stage 1: Composer (Backend Dependencies)
# ============================================================
FROM composer:2.8 AS vendor
WORKDIR /app

# Copy only composer files for better caching
COPY composer.json composer.lock ./

# Install only production dependencies (no dev)
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

# Copy full source and regenerate optimized autoload
COPY . .
RUN composer dump-autoload --optimize


# ============================================================
# Stage 2: Node (Frontend Build)
# ============================================================
FROM node:20-alpine AS frontend
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Copy app source
COPY . .

# --- Skip Wayfinder build logic safely ---
# Disable vite-plugin-wayfinder build without needing PHP
ENV WAYFINDER_SKIP_BUILD=1

# Build frontend (no PHP or artisan involved)
RUN npm run build:ci || npm run build


# ============================================================
# Stage 3: PHP-FPM (Final Production Image)
# ============================================================
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www

# Install PHP extensions and tools
RUN apk add --no-cache \
    libpq-dev \
    libzip-dev \
    zip unzip \
    bash shadow supervisor \
    && docker-php-ext-install pdo pdo_mysql bcmath opcache

# Copy application code and vendor from composer stage
COPY --from=vendor /app /var/www
COPY --from=vendor /app/vendor /var/www/vendor

# Copy built frontend from Node stage
COPY --from=frontend /app/public /var/www/public

# Laravel optimizations (ignore errors if no .env yet)
RUN php artisan config:clear || true \
 && php artisan cache:clear || true \
 && php artisan route:clear || true \
 && php artisan view:clear || true \
 && php artisan optimize || true

# Set permissions for Laravel writable directories
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
 && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
