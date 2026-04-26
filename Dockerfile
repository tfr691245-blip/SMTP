# Use Alpine for the smallest, fastest footprint
FROM alpine:latest

# 1. Install Postfix, Nginx, and PHP 8.3
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    cyrus-sasl-login \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Master Level Postfix Optimization
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "maillog_file = /dev/stdout" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "smtp_tls_verify_cert_match = nexthop" \
    && postconf -e "minimal_backoff_time = 30s" \
    && postconf -e "maximal_backoff_time = 120s" \
    && /usr/bin/newaliases

# 3. Configure Nginx for the Modern UI
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php index.html; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Copy your Modern UI file
# Ensure index.php is in the same folder as this Dockerfile
COPY index.php /var/www/localhost/htdocs/index.php

# 5. Set permissions
RUN chown -R lighttpd:lighttpd /var/www/localhost/htdocs

# 6. Open Web (80) and SMTP (25/587)
EXPOSE 80 25 587

# 7. Start all services: PHP-FPM, Nginx, and Postfix
CMD php-fpm83 && nginx && postfix start-fg
