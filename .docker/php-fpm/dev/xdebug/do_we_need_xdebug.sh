#!/bin/sh
set -e

if [ "${BUILD_ARGUMENT_ENV}" = "dev" ] || [ "${BUILD_ARGUMENT_ENV}" = "test" ]; then
    pecl install xdebug
    docker-php-ext-enable xdebug
else
    rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi
