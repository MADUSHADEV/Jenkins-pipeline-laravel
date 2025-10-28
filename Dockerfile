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
        autoconf \
        gcc \
        g++ \
        make \
        bison \
        re2c \
        $PHPIZE_DEPS \
        libpq-dev \
        libzip-dev \
        nodejs \
        npm

# Install required PHP extensions
RUN docker-php-ext-install pdo_mysql pdo_pgsql zip bcmath tokenizer xml curl

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Clean up build dependencies AFTER extensions are installed
RUN apk del autoconf gcc g++ make bison re2c $PHPIZE_DEPS

# ... (rest of the Dockerfile: COPY commands, npm install/build, chown, EXPOSE, CMD) ...
COPY --from=vendor /app/vendor/ /var/www/vendor/
# Copy the rest of the application code
COPY . /var/www/
# Install Node.js dependencies and build frontend assets
RUN npm install
# Build the frontend assets
RUN npm run build
# Set proper permissions for Laravel storage and cache directories
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
# Expose port 9000 and start PHP-FPM server
EXPOSE 9000
# Start PHP-FPM server
CMD ["php-fpm"]