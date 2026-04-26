FROM alpine:latest

# 1. Install Stack
RUN apk add --no-cache \
    postfix cyrus-sasl ca-certificates tzdata \
    nginx php83 php83-fpm \
    && update-ca-certificates

# 2. Your Verified Mail Config
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "maillog_file = /dev/stdout" \
    && /usr/bin/newaliases

# 3. Nginx Gateway (Optimized to prevent 504)
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 300; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Web UI for any Sender/Receiver
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to']; $sub = $_POST['subject']; $msg = $_POST['message']; $name = $_POST['name'];
    $h = "From: $name <verified@elite.qzz.io>\r\nContent-Type: text/html; charset=UTF-8";
    mail($to, $sub, $msg, $h) ? $r="OK" : $r="FAIL";
}
?>
<!DOCTYPE html><html><body style="background:#000;color:#0f0;font-family:monospace;padding:20px;">
<h3>APEX_RELAY_UI</h3>
<form method="POST">
<input name="name" placeholder="Sender Name" style="width:100%;background:#111;color:#0f0;border:1px solid #333;padding:10px;margin-bottom:10px;"><br>
<input name="to" placeholder="Receiver Email" style="width:100%;background:#111;color:#0f0;border:1px solid #333;padding:10px;margin-bottom:10px;"><br>
<input name="subject" placeholder="Subject" style="width:100%;background:#111;color:#0f0;border:1px solid #333;padding:10px;margin-bottom:10px;"><br>
<textarea name="message" placeholder="HTML Message" style="width:100%;height:150px;background:#111;color:#0f0;border:1px solid #333;padding:10px;margin-bottom:10px;"></textarea><br>
<button type="submit" style="width:100%;padding:10px;background:#00f;color:#fff;border:none;">EXECUTE DEPLOY</button>
</form>
<p>STATUS: <?php echo $r; ?></p>
</body></html>
EOF

# 5. Startup Sequence (The 504 Fix)
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
# Force PHP to start first, wait, then Nginx, then Postfix in background
CMD php-fpm83 && sleep 3 && nginx && postfix start-fg
