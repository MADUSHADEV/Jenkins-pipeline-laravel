# Stage 1: Install backend dependencies with Composer
# Using specific alpine version for consistency and security
FROM composer:2.8 AS vendor

# Set working directory
WORKDIR /app

# Copy composer manifests
COPY composer.json composer.json
COPY composer.lock composer.lock

# Install PHP dependencies optimized for production
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

# --- Stage 2 (Frontend Build) Removed ---

# Stage 3: Final application image (Includes Node build)
# Using specific alpine version
FROM php:8.3-fpm-alpine AS final

# Set working directory
WORKDIR /var/www

# Install system dependencies 
# Added nodejs and npm
# Added build dependencies ($PHPIZE_DEPS) needed for PECL Redis install
RUN apk add --no-cache \
        $PHPIZE_DEPS \
        libpq-dev \
        libzip-dev \
        nodejs \
        npm

# Install required PHP extensions
# Added common Laravel extensions often needed: tokenizer, xml, curl
RUN docker-php-ext-install pdo_mysql pdo_pgsql zip bcmath tokenizer xml curl

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Clean up build dependencies after PECL install
RUN apk del $PHPIZE_DEPS

# Copy Composer dependencies from vendor stage
COPY --from=vendor /app/vendor/ /var/www/vendor/

# Copy the entire application code first
# This includes frontend source files needed for npm install/build
COPY . /var/www/

# Install Node.js dependencies
RUN npm install

# Build frontend assets (PHP is available in this stage)
RUN npm run build

# --- Optional Cleanup: Remove Node.js/npm after build ---
# Uncomment the line below if you want the smallest possible final image
# RUN apk del nodejs npm

# Set permissions for Laravel storage and cache directories
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]