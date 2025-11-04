# Stage 1: Install backend dependencies with Composer
# Using specific alpine version for consistency and security
FROM composer:2.8 AS vendor

# Set working directory
WORKDIR /app

# Copy composer manifests
COPY composer.json composer.json
COPY composer.lock composer.lock

# Install PHP dependencies optimized for production
RUN composer install --no-dev --no-scripts --prefer-dist 

# Now, generate an optimized autoloader that ignores dev-only providers
RUN composer dump-autoload --no-dev --optimize

# --- Stage 2 (Frontend Build) Removed ---

# Stage 3: Final application image (Includes Node build)
# Using specific alpine version
FROM php:8.3-fpm-alpine AS final

# Set working directory
WORKDIR /var/www

# Install system dependencies 
# Added nodejs and npm
# Added php83 extensions for mysql, pgsql, zip, bcmath, tokenizer, xml, curl, redis
RUN apk add --no-cache \
        # PHP Extensions
        php83-pdo_mysql \
        php83-pdo_pgsql \
        php83-zip \
        php83-bcmath \
        php83-tokenizer \
        php83-xml \
        php83-curl \
        php83-redis \
        # Node.js
        nodejs \
        npm \
        # Other dependencies (needed if you still compile some extensions)
        # Keep for pecl or manual compiles if needed later
        $PHPIZE_DEPS \ 
        libpq-dev \
        libzip-dev

# --- Remove docker-php-ext-install and pecl install ---
# We are now using apk for these extensions

# Clean up build dependencies (keep only runtime deps)
# We remove PHPIZE_DEPS now as they are usually not needed after apk install
RUN apk del $PHPIZE_DEPS

# Copy the entire application code first
COPY . /var/www/

# Copy Composer dependencies
COPY --from=vendor /app/vendor/ /var/www/vendor/

# Install Node.js dependencies
RUN npm install

# --- THE FIX IS HERE ---
# Create a temporary .env file from the example for the build step
# and generate the application key. This is needed for artisan commands.
RUN cp .env.example .env
RUN php artisan key:generate

# Build frontend assets
RUN npm run build

# --- Optional Cleanup: Remove Node.js/npm after build ---
RUN apk del nodejs npm

# Set permissions for Laravel storage and cache directories
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]