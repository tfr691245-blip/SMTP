FROM alpine:latest

# 1. Install System Stack (Postfix + SASL + Nginx + PHP)
RUN apk add --no-cache \
    postfix \
    cyrus-sasl \
    cyrus-sasl-login \
    cyrus-sasl-plain \
    ca-certificates \
    tzdata \
    nginx \
    php83 \
    php83-fpm \
    && update-ca-certificates

# 2. Apply your Verified Postfix Logic
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "maillog_file = /dev/stdout" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && /usr/bin/newaliases

# 3. Configure Nginx for the Web Interface
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

# 4. Create the Customizable Web UI (index.php)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$msg = "";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to'];
    $from_name = $_POST['from_name'];
    $subject = $_POST['subject'];
    $body = $_POST['body'];
    
    // Custom Headers to support "Any Sender Name"
    $headers = "From: $from_name <verified@elite.qzz.io>\r\n";
    $headers .= "MIME-Version: 1.0\r\n";
    $headers .= "Content-Type: text/html; charset=UTF-8\r\n";

    if (mail($to, $subject, $body, $headers)) {
        $msg = "<div class='text-green-500'>[SUCCESS] Message sent to $to</div>";
    } else {
        $msg = "<div class='text-red-500'>[ERROR] Injection failed.</div>";
    }
}
?>
<!DOCTYPE html><html><head><script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-slate-950 text-white p-5 font-monospace">
    <div class="max-w-xl mx-auto bg-slate-900 p-8 rounded-xl border border-slate-800 shadow-2xl">
        <h2 class="text-blue-500 font-bold mb-5 tracking-tighter uppercase">Apex Web Relay</h2>
        <?php echo $msg; ?>
        <form method="POST" class="space-y-4 mt-4">
            <input name="from_name" placeholder="Sender Display Name (e.g. Support)" class="w-full p-3 bg-black border border-slate-700 rounded outline-none focus:border-blue-500">
            <input name="to" placeholder="Recipient Email" required class="w-full p-3 bg-black border border-slate-700 rounded outline-none focus:border-blue-500">
            <input name="subject" placeholder="Subject" required class="w-full p-3 bg-black border border-slate-700 rounded outline-none focus:border-blue-500">
            <textarea name="body" placeholder="HTML or Text Body" rows="5" required class="w-full p-3 bg-black border border-slate-700 rounded outline-none focus:border-blue-500"></textarea>
            <button type="submit" class="w-full bg-blue-600 hover:bg-blue-500 py-3 font-bold rounded transition">EXECUTE DEPLOY</button>
        </form>
        <div class="mt-6 text-[10px] text-slate-500 uppercase">Queue Status: <?php system("postqueue -p | grep -c '^'"); ?> active tasks</div>
    </div>
</body></html>
EOF

# 5. Fix Permissions & Start All Services
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm83 && nginx && postfix start-fg
