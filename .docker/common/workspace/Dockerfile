# Development workspace image for Laravel applications
# This Dockerfile creates a PHP FPM environment with Node.js integration for Laravel development
# It includes PHP extensions, Composer, Node.js, and user permission handling

# Base image for Node.js
FROM node:23-alpine3.21 AS node_base

# Main PHP image
FROM php:8.4-fpm-alpine3.21

# HOST_UID and HOST_GID allow matching container user with host user permissions
# WORKDIR sets the default working directory for the application
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG WORKDIR=/var/www/html

# Install PHP extensions and dependencies
# - icu-dev: Required for intl extension
# - libzip-dev: Required for zip extension
# - linux-headers: Required for some PHP extensions
# Then install PHP extensions:
# - pdo_mysql: MySQL database driver
# - opcache: PHP performance optimization
# - intl: Internationalization functions
# - zip: ZIP file manipulation
# - redis: Redis caching driver
# - xdebug: Debugging and profiling tool
RUN apk add --no-cache \
    git \
    icu-dev \ 
    libzip-dev \
    linux-headers \
    && apk add --no-cache --virtual .build-deps ${PHPIZE_DEPS} \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    opcache \
    intl \
    zip \
    && pecl install \
    redis \
    xdebug \
    && docker-php-ext-enable \
    redis \
    xdebug

# Install Composer (PHP dependency manager)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy Node.js binaries and modules from the node_base stage
COPY --from=node_base /usr/local/bin/node /usr/local/bin/node
COPY --from=node_base /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node_base /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node_base /usr/local/bin/npx /usr/local/bin/npx

# Fix npm and npx symbolic links to ensure they work properly
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Copy PHP and Xdebug configuration files
COPY .docker/php-fpm/dev/php.ini /usr/local/etc/php/php.ini
COPY .docker/php-fpm/dev/xdebug/xdebug-main.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Create a non-root user that matches the host user's UID/GID
# This ensures proper file permissions when mounting volumes
# Also adds the user to the wheel group for sudo capabilities if needed
RUN if getent group ${HOST_GID} > /dev/null; then \
        GROUP_NAME=$(getent group ${HOST_GID} | cut -d: -f1) && \
        adduser -D -u ${HOST_UID} -G ${GROUP_NAME} -s /bin/sh www; \
    else \
        addgroup -g ${HOST_GID} www && \
        adduser -D -u ${HOST_UID} -G www -s /bin/sh www; \
    fi \
    && adduser www wheel

# Switch to non-root user for better security
USER www

# Set the working directory for all subsequent operations
WORKDIR ${WORKDIR}

# Override the entrypoint to avoid the default php entrypoint
ENTRYPOINT []

# Default command to keep the container running
CMD ["sh"]
