#!/bin/bash
#!/bin/sh
set -e

if [ "${NGINX_HTTPS_ENABLED}" = "true" ]; then
    # set the HTTPS_CONFIG environment variable to the content of the https.conf.template
    HTTPS_CONFIG=$(envsubst < /etc/nginx/https.conf.template)
    export HTTPS_CONFIG
    # Substitute the HTTPS_CONFIG in the default.conf.template with content from https.conf.template
    envsubst '${HTTPS_CONFIG}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
fi
echo "Docker entrypoint script is running"

if [ "${NGINX_CREATE_CERTBOT_CHALNENGE_LOCATION}" = "true" ]; then
    ACME_CHALLENGE_LOCATION='location /.well-known/acme-challenge/ { root /var/www/html; }'
else
    ACME_CHALLENGE_LOCATION=''
fi
export ACME_CHALLENGE_LOCATION

env_vars=$(printenv | cut -d= -f1 | sed 's/^/$/g' | paste -sd, -)
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

envsubst "$env_vars" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
envsubst "$env_vars" < /etc/nginx/proxy.conf.template > /etc/nginx/proxy.conf

envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Start Nginx using the default entrypoint
exec nginx -g 'daemon off;'
echo "\nExecuting command: $@"
exec "$@"
