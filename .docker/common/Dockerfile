ARG HOST_UID=1000
ARG HOST_GID=1000
ARG BUILD_ARGUMENT_ENV=prod
ARG WORKDIR=/var/www/html

# Base layer for backend dependencies
# Installs PHP extensions and composer dependencies
FROM composer:2.8 AS be_base

ARG WORKDIR

WORKDIR ${WORKDIR}

# Install PHP extensions required by the application
RUN apk add --no-cache --virtual .build-deps ${PHPIZE_DEPS} && \
    apk add --no-cache \
        linux-headers \
        fcgi \
        icu-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        opcache \
        intl \
        zip \
    && pecl install \
        redis \
    && docker-php-ext-enable \
        redis

# Copy composer files and install dependencies
COPY --chown=composer:composer ./composer.json ./composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-progress --no-interaction
COPY --chown=composer:composer . ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction

# Frontend build layer
# Builds JavaScript/CSS assets
FROM node:23-alpine3.21 AS fe_base

ARG WORKDIR

WORKDIR ${WORKDIR}

# Copy files from backend layer and build frontend assets
COPY --from=be_base ${WORKDIR}/package.json ${WORKDIR}/package-lock.json* ./
COPY --from=be_base ${WORKDIR} ./
RUN npm i --quiet && \
    npm run build

# PHP-FPM application server layer
# Contains the PHP runtime with extensions and application code
FROM php:8.4-fpm-alpine3.21 AS fpm_server

ARG HOST_UID
ARG HOST_GID
ARG BUILD_ARGUMENT_ENV
ARG WORKDIR
ENV ENV=$BUILD_ARGUMENT_ENV

WORKDIR ${WORKDIR}

# Install PHP extensions required by the application
RUN apk add --no-cache --virtual .build-deps ${PHPIZE_DEPS} && \
    apk add --no-cache \
        linux-headers \
        fcgi \
        icu-dev \
        libzip-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        opcache \
        intl \
        zip \
    && pecl install \
        redis \
    && docker-php-ext-enable \
        redis

# Install composer and PHP-FPM healthcheck
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    curl -sSL -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck \
    && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf

# Create a new user with the specified HOST_UID and HOST_GID, reusing an existing group if HOST_GID exists
RUN if [ "${BUILD_ARGUMENT_ENV}" = "dev" ] || [ "${BUILD_ARGUMENT_ENV}" = "test" ]; then \
        if getent group ${HOST_GID} > /dev/null; then \
            GROUP_NAME=$(getent group ${HOST_GID} | cut -d: -f1) && \
            adduser -D -u ${HOST_UID} -G ${GROUP_NAME} -s /bin/sh www; \
        else \
            addgroup -g ${HOST_GID} www && \
            adduser -D -u ${HOST_UID} -G www -s /bin/sh www; \
        fi && \
            sed -i "s/user = www-data/user = www/g" /usr/local/etc/php-fpm.d/www.conf && \
            sed -i "s/group = www-data/group = $GROUP_NAME/g" /usr/local/etc/php-fpm.d/www.conf ;\
    fi

# PHP configuration for Laravel
COPY .docker/php-fpm/$BUILD_ARGUMENT_ENV/php.ini /usr/local/etc/php/php.ini

# Install and configure Xdebug
COPY .docker/php-fpm/dev/xdebug/xdebug-main.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY .docker/php-fpm/dev/xdebug/do_we_need_xdebug.sh /temp/
RUN chmod +x /temp/do_we_need_xdebug.sh && /temp/do_we_need_xdebug.sh

# Setup application entrypoint
COPY .docker/php-fpm/$BUILD_ARGUMENT_ENV/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy application code, storage directory for initialization, and built frontend assets
COPY --from=be_base ${WORKDIR} ./
COPY --from=be_base ${WORKDIR}/storage ./storage-init/
COPY --from=fe_base ${WORKDIR}/public ./public/
    
RUN chown -R www-data:www-data ${WORKDIR}

USER www-data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm"]

# Nginx web server layer
# Serves static content and proxies PHP requests to FPM
FROM nginx:1.27.4-alpine3.21 AS nginx_server

ARG WORKDIR
ARG BUILD_ARGUMENT_ENV

# Configure logging and remove default configs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /etc/nginx/conf.d/*

# Copy nginx configuration based on environment
COPY .docker/nginx/$BUILD_ARGUMENT_ENV/nginx.conf /etc/nginx/nginx.conf
COPY .docker/nginx/$BUILD_ARGUMENT_ENV/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Copy static files from PHP-FPM layer
COPY --from=fpm_server ${WORKDIR}/public ${WORKDIR}/public

WORKDIR ${WORKDIR}