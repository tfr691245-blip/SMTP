FROM alpine:latest

# 1. Install System Stack
# Removed 'cyrus-sasl-plain' as it's built into cyrus-sasl in Alpine
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Master Postfix Logic
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && postconf -e "maillog_file = /dev/stdout" \
    && /usr/bin/newaliases

# 3. Nginx Configuration
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
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Customizable UI (index.php)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$status = "";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to'];
    $sub = $_POST['subject'];
    $body = $_POST['body'];
    $name = $_POST['name'];
    $headers = "From: $name <verified@elite.qzz.io>\r\nContent-Type: text/html; charset=UTF-8";
    if (mail($to, $sub, $body, $headers)) { $status = "OK"; } 
    else { $status = "ERROR"; }
}
?>
<!DOCTYPE html><html><head><script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-black text-gray-300 p-6 font-mono">
    <div class="max-w-xl mx-auto border border-gray-800 p-8 rounded-lg">
        <h1 class="text-blue-500 font-bold mb-4 uppercase tracking-widest">Apex Relay UI</h1>
        <form method="POST" class="space-y-4">
            <input name="name" placeholder="Sender Name" class="w-full p-3 bg-zinc-900 border border-zinc-800 rounded">
            <input name="to" placeholder="Recipient" required class="w-full p-3 bg-zinc-900 border border-zinc-800 rounded">
            <input name="subject" placeholder="Subject" required class="w-full p-3 bg-zinc-900 border border-zinc-800 rounded">
            <textarea name="body" placeholder="HTML Body" rows="5" required class="w-full p-3 bg-zinc-900 border border-zinc-800 rounded"></textarea>
            <button class="w-full bg-blue-700 py-3 font-bold uppercase hover:bg-blue-600">Execute</button>
        </form>
        <div class="mt-4 text-[10px] text-gray-600">STATUS: <?php echo $status; ?></div>
    </div>
</body></html>
EOF

# 5. Perms & Launch
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx && postfix start-fg
