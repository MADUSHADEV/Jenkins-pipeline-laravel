# Stage 1: The "Builder" stage with all tools
FROM php:8.3-alpine AS builder

# Install system dependencies including git, zip dev library, and nodejs
RUN apk add --no-cache git unzip libzip-dev nodejs npm

# Install Composer globally
COPY --from=composer:lts /usr/bin/composer /usr/bin/composer

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip

# Set the working directory
WORKDIR /app

# Copy the entire application
COPY . .

# Install Composer dependencies and generate optimized autoloader
RUN composer install --no-dev --prefer-dist --optimize-autoloader

# Create the .env file and generate the key
RUN cp .env.example .env
RUN php artisan key:generate

# Install NPM dependencies and build the frontend
RUN npm install
RUN npm run build


# Stage 2: The final, clean production image
FROM php:8.3-fpm-alpine

# Set the working directory
WORKDIR /var/www

# Install only the required runtime PHP libraries
RUN apk add --no-cache libzip
# Install the required PHP extensions
RUN docker-php-ext-install pdo_mysql zip

# Copy the fully built application (with vendor and public/build) from the builder stage
COPY --from=builder /app /var/www

# Set correct ownership for Laravel
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]