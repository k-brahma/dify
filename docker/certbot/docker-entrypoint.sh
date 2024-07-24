#!/bin/sh
set -e

echo "Docker entrypoint script is running"

echo "\nChecking specific environment variables:"
echo "CERTBOT_EMAIL: ${CERTBOT_EMAIL:-Not set}"
echo "CERTBOT_DOMAIN: ${CERTBOT_DOMAIN:-Not set}"
echo "CERTBOT_OPTIONS: ${CERTBOT_OPTIONS:-Not set}"

echo "\nChecking mounted directories:"
for dir in "/etc/letsencrypt" "/var/www/html" "/var/log/letsencrypt"; do
    if [ -d "$dir" ]; then
        echo "$dir exists. Contents:"
        ls -la "$dir"
    else
        echo "$dir does not exist or is not mounted."
    fi
done

echo "\nExecuting command: $@"
exec "$@"