# Stage 1: Install backend dependencies with Composer
FROM composer:2.8 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --prefer-dist --optimize-autoloader

# Stage 2: Node dependencies and frontend build
FROM node:18-alpine AS frontend
WORKDIR /app
COPY package*.json vite.config.ts ./
COPY resources ./resources
COPY artisan ./artisan
COPY bootstrap ./bootstrap
COPY config ./config
COPY app ./app
COPY --from=vendor /app/vendor ./vendor
RUN npm install
RUN echo "APP_ENV=production" > .env
RUN npm run build

# Stage 3: Final PHP runtime
FROM php:8.3-fpm-alpine AS final
WORKDIR /var/www

# Install PHP extensions
RUN apk add --no-cache \
    php83-pdo_mysql php83-pdo_pgsql php83-zip php83-bcmath php83-tokenizer \
    php83-xml php83-curl php83-redis $PHPIZE_DEPS libpq-dev libzip-dev

# Copy all Laravel application code first
COPY . .

# Then copy vendor and built assets (these override what's needed)
COPY --from=vendor /app/vendor /var/www/vendor
COPY --from=frontend /app/public/build /var/www/public/build

# Fix permissions
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
