# Stage 1: Install backend dependencies with Composer
FROM composer:2.8 AS vendor
WORKDIR /app
# Copy manifests first to leverage Docker cache
COPY composer.json composer.json
COPY composer.lock composer.lock
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

# Stage 2: Final application image
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www
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

# --- THE FIX IS HERE ---
# Copy the application code FIRST
COPY . /var/www/

# NOW, copy the vendor directory ON TOP of the application code
COPY --from=vendor /app/vendor/ /var/www/vendor/
# ---------------------

# NEW: Set up a minimal .env for build-time bootstrapping
# This assumes .env.example exists; adjust if your project uses a different template.
RUN cp .env.example .env
# Generate APP_KEY to allow Laravel to boot without configuration errors
RUN php artisan key:generate

# Now we can run npm install and build, because package.json is present
RUN npm install
RUN npm run build

# --- Optional Cleanup: Remove Node.js/npm after build ---
# RUN apk del nodejs npm

# Set permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]