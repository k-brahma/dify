#!/bin/bash
set -e

# Generate Nginx configuration from templates
envsubst '${NGINX_SERVER_NAME} ${NGINX_PORT} ${NGINX_SSL_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

if [ "$NGINX_HTTPS_ENABLED" = "true" ]; then
    HTTPS_CONFIG=$(envsubst '${NGINX_SSL_PORT} ${NGINX_SSL_CERT_FILENAME} ${NGINX_SSL_CERT_KEY_FILENAME} ${NGINX_SSL_PROTOCOLS}' < /etc/nginx/https.conf.template)
else
    HTTPS_CONFIG=""
fi

if [ "$USE_CERTBOT" = "true" ]; then
    ACME_CHALLENGE_LOCATION="location /.well-known/acme-challenge/ { root /var/www/certbot; }"
else
    ACME_CHALLENGE_LOCATION=""
fi

envsubst '${NGINX_PORT} ${NGINX_SERVER_NAME} ${HTTPS_CONFIG} ${ACME_CHALLENGE_LOCATION}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Certbot integration
if [ "$USE_CERTBOT" = "true" ]; then
    mkdir -p /var/www/certbot
    if [ ! -e "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" ]; then
        certbot certonly --webroot -w /var/www/certbot \
            -d ${CERTBOT_DOMAIN} --email ${CERTBOT_EMAIL} \
            --agree-tos --no-eff-email --force-renewal
    fi

    # Copy Certbot certificates to Nginx SSL directory
    mkdir -p /etc/nginx/ssl
    cp /etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem /etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}
    cp /etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem /etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}

    # Set appropriate permissions
    chmod 644 /etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}
    chmod 600 /etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}

    # Set up automatic renewal and copy
    (
        while :; do
            sleep 12h
            certbot renew --quiet
            cp /etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem /etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}
            cp /etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem /etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}
            chmod 644 /etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}
            chmod 600 /etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}
            nginx -s reload
        done
    ) &
else
    # Check and set appropriate permissions for existing SSL certificates
    if [ -f "/etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}" ] && [ -f "/etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}" ]; then
        chmod 644 /etc/nginx/ssl/${NGINX_SSL_CERT_FILENAME}
        chmod 600 /etc/nginx/ssl/${NGINX_SSL_CERT_KEY_FILENAME}
    fi
fi

# Test Nginx configuration
nginx -t

# Start Nginx
exec nginx -g 'daemon off;'