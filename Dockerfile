FROM alpine:latest

# 1. Install everything
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
    && /usr/bin/newaliases

# 3. Configure Nginx with LOGGING enabled
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    access_log /dev/stdout; \
    error_log /dev/stderr; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 300; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Bake the UI
RUN echo "<?php phpinfo(); ?>" > /var/www/localhost/htdocs/index.php

# 5. Fix PHP-FPM to log to stdout
RUN sed -i "s|;error_log = log/php83/error.log|error_log = /dev/stderr|" /etc/php83/php-fpm.conf && \
    sed -i "s|listen = 127.0.0.1:9000|listen = 127.0.0.1:9000|" /etc/php83/php-fpm.d/www.conf

# 6. Final Permissions
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80 587

# 7. Start with full logging
CMD php-fpm83 && nginx && postfix start-fg
