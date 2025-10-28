# Stage 1: Install backend dependencies with Composer
FROM composer:2.8 AS vendor

# Set working directory
WORKDIR /app

# Copy composer manifests
COPY composer.json composer.json
COPY composer.lock composer.lock

# Install PHP dependencies
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

# Stage 2: Build frontend assets with Node.js
FROM node:22.21-alpine AS frontend

# Set working directory
WORKDIR /app

# Copy frontend package manifests
COPY package.json package.json
COPY package-lock.json package-lock.json
COPY vite.config.ts vite.config.ts
COPY components.json components.json
COPY resources/ resources/

# Install Node.js dependencies
RUN npm install

# Build frontend assets
RUN npm run build

# Stage 3: Final application image
FROM php:8.3-fpm-alpine AS Final

# Set working directory
WORKDIR /var/www

# Copy composer dependencies from vendor stage
COPY --from=vendor /app/vendor/  /var/www/vendor/

# Copy frontend assets from frontend stage
COPY --from=frontend /app/public/build/ /var/www/public/build/

# Copy the rest of the application code
COPY . /var/www/

# Install system dependencies needed for extensions
RUN apk add --no-cache \
              # Build tools
              $PHPIZE_DEPS \
              # For PostgreSQL
              libpq-dev \
              # For Zip
              libzip-dev

# Install required PHP extensions
RUN docker-php-ext-install pdo_mysql pdo_pgsql zip bcmath

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Set permissions for Laravel storage and cache directories
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port 9000 and start PHP-FPM server
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]
