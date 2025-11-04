# Stage 1: Build the vendor directory
FROM composer:2.8 as vendor
WORKDIR /app
COPY . .
# Generate an optimized autoloader for production
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# Stage 2: Build frontend assets
FROM node:18-alpine as frontend
WORKDIR /app
COPY . .
# Copy the production vendor directory from the previous stage
COPY --from=vendor /app/vendor /app/vendor
# Create a temporary env file for the build
RUN cp .env.example .env
RUN php artisan key:generate
RUN npm install
RUN npm run build

# Stage 3: Final production image
FROM php:8.3-fpm-alpine
WORKDIR /var/www

# Install only necessary PHP extensions for a lean image
RUN apk add --no-cache \
        php83-pdo_mysql \
        php83-pdo_pgsql \
        php83-zip \
        php83-bcmath \
        php83-curl \
        php83-redis

# Copy the final application code from the frontend stage (which has everything)
COPY --from=frontend /app /var/www

# Set correct ownership for Laravel
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]