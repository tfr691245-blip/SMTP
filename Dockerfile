FROM alpine:latest

# 1. Install Stack (Added cyrus-sasl-plain back as it is often needed)
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

# 3. Nginx Setup with REQUIRED directory fixes
RUN mkdir -p /run/nginx /var/www/localhost/htdocs && \
    echo 'server { \
    listen 80; \
    server_name _; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Web UI Logic
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$r = "READY";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to']; $sub = $_POST['subject']; $msg = $_POST['msg']; $name = $_POST['name'];
    $h = "From: $name <verified@elite.qzz.io>\r\nContent-Type: text/html; charset=UTF-8";
    $r = mail($to, $sub, $msg, $h) ? "SENT" : "FAIL";
}
?>
<!DOCTYPE html><html><body style="background:#000;color:#0f0;font-family:monospace;padding:20px;">
<h2>APEX_V4_STABLE</h2>
<form method="POST" style="display:flex;flex-direction:column;gap:10px;max-width:400px;">
<input name="name" placeholder="Sender Name" style="background:#111;color:#0f0;border:1px solid #333;padding:10px;">
<input name="to" placeholder="To" required style="background:#111;color:#0f0;border:1px solid #333;padding:10px;">
<input name="subject" placeholder="Subject" required style="background:#111;color:#0f0;border:1px solid #333;padding:10px;">
<textarea name="msg" placeholder="Message" required style="background:#111;color:#0f0;border:1px solid #333;padding:10px;height:100px;"></textarea>
<button type="submit" style="background:#00f;color:#fff;padding:10px;border:none;cursor:pointer;">DEPLOY</button>
</form>
<p>STATUS: <?php echo $r; ?></p>
</body></html>
EOF

# 5. Correct Permissions & Startup Script
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80

# The startup must ensure directories exist and services stay up
CMD ["/bin/sh", "-c", "php-fpm83 && nginx && postfix start-fg"]
