#!/bin/sh
set -e

# Check if $HOST_UID and $HOST_GID are set, else fallback to default (1000:1000)
USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

# Fix file ownership and permissions using the passed HOST_UID and HOST_GID
echo "Fixing file permissions with HOST_UID=${USER_ID} and HOST_GID=${GROUP_ID}..."
chown -R ${USER_ID}:${GROUP_ID} /var/www/html || echo "Some files could not be changed"

php artisan migrate --force

# Clear configurations to avoid caching issues in development
echo "Clearing configurations..."
php artisan optimize:clear

# Run the default command (e.g., php-fpm or bash)
exec "$@"