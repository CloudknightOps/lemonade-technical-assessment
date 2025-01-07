# Use PHP 8.3 with Apache as the base image
FROM php:8.3-apache

# Set environment variables for better caching and optimization
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_NO_INTERACTION=1

# Install system dependencies
# - git: Required for Composer to clone packages
# - unzip: Required for Composer to unzip packages
# - libzip-dev: Required for the zip PHP extension
# - curl: Required for downloading additional tools
# - nano: For text editing if needed inside container
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    curl \
    nano \
    && docker-php-ext-install zip pdo_mysql \
    # Clean up the apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite for URL rewriting
RUN a2enmod rewrite

# Install Composer (PHP package manager)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory for the application
WORKDIR /var/www/html

# Copy application files
# Note: This assumes your .dockerignore excludes vendor/, node_modules/, etc.
COPY . .

# Set proper permissions for Laravel
# - storage: Required for Laravel to write logs, cache, and uploaded files
# - bootstrap/cache: Required for Laravel to store framework bootstrap files
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Install Node.js and npm
# This layer installs Node.js 18.x and the latest npm version
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install --global npm \
    # Clean up the apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# Install PHP and Node.js dependencies
# --no-dev: Exclude development dependencies
# --optimize-autoloader: Optimize Composer's autoloader
# npm run build: Compile frontend assets
RUN composer install --no-dev --optimize-autoloader \
    && npm install \
    && npm run build \
    # Clean up npm cache to reduce image size
    && npm cache clean --force

# Expose port 80 for Apache
EXPOSE 80

# Optional: Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1
