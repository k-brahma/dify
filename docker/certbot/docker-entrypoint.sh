#!/bin/sh
set -e

# Debug output
echo "Docker entrypoint script is running"

# Check if specific environment variables are set
echo "\nChecking specific environment variables:"
echo "CERTBOT_EMAIL: ${CERTBOT_EMAIL:-Not set}"
echo "CERTBOT_DOMAIN: ${CERTBOT_DOMAIN:-Not set}"
echo "CERTBOT_OPTIONS: ${CERTBOT_OPTIONS:-Not set}"

# Check if mounted directories exist
echo "\nChecking mounted directories:"
for dir in "/etc/letsencrypt" "/var/www/html" "/var/log/letsencrypt"; do
    if [ -d "$dir" ]; then
        echo "$dir exists. Contents:"
        ls -la "$dir"
    else
        echo "$dir does not exist."
    fi
done

# Generate update-cert.sh from template
envsubst < /update-cert.sh.template > /update-cert.sh
chmod +x /update-cert.sh

# Execute the command specified in the Docker Compose file
echo "\nExecuting command: $@"
exec "$@"