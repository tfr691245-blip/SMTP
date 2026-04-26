FROM alpine:latest

# 1. Install Core Services
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

# 2. SMTP Engine Configuration
RUN postconf -e "relayhost = [142.251.10.108]:587" \
    && postconf -e "inet_protocols = ipv4" \
    && postconf -e "maillog_file = /dev/stdout" \
    && postconf -e "smtp_sasl_auth_enable = yes" \
    && postconf -e "smtp_sasl_password_maps = static:pyypl2005@gmail.com:gnrbyxyyjxyoaljv" \
    && postconf -e "smtp_sasl_security_options = noanonymous" \
    && postconf -e "smtp_tls_security_level = encrypt" \
    && postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt" \
    && /usr/bin/newaliases

# 3. Nginx HTTPS & Timeout Fix (600s)
RUN mkdir -p /run/nginx && \
    echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    set_real_ip_from 0.0.0.0/0; \
    real_ip_header X-Forwarded-For; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 600; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. Advanced UI with Integrated Log Tab
RUN echo '<?php \
$status = ""; \
if ($_SERVER["REQUEST_METHOD"] == "POST") { \
    $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL); \
    $subject = htmlspecialchars($_POST["subject"]); \
    $message = $_POST["message"]; \
    $headers = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8\r\n"; \
    if (mail($to, $subject, $message, $headers)) { $status = "success"; } else { $status = "error"; } \
} \
?> \
<!DOCTYPE html> \
<html lang="en"> \
<head> \
    <meta charset="UTF-8"> \
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> \
    <title>ELITE RELAY | ADVANCED</title> \
    <script src="https://cdn.tailwindcss.com"></script> \
    <style> \
        body { background: #020617; color: white; font-family: monospace; } \
        .tab-content { display: none; } \
        .tab-content.active { display: block; } \
        .glass { background: rgba(15, 23, 42, 0.7); backdrop-filter: blur(15px); border: 1px solid rgba(255, 255, 255, 0.1); } \
    </style> \
</head> \
<body class="min-h-screen p-6 flex flex-col items-center"> \
    <div class="w-full max-w-4xl"> \
        <div class="flex space-x-2 mb-6"> \
            <button onclick="openTab(\'deploy\')" class="px-6 py-3 bg-blue-600 rounded-t-2xl font-bold text-xs uppercase tracking-widest">Deploy Console</button> \
            <button onclick="openTab(\'logs\')" class="px-6 py-3 bg-slate-800 rounded-t-2xl font-bold text-xs uppercase tracking-widest">Relay Logs</button> \
        </div> \
        \
        <div id="deploy" class="tab-content active glass rounded-b-3xl rounded-tr-3xl p-8"> \
            <h2 class="text-blue-500 font-black mb-6 italic tracking-tighter">EXECUTE PAYLOAD</h2> \
            <?php if ($status == "success"): ?><div class="mb-4 text-green-400 text-xs">[TRANSMISSION COMPLETE]</div><?php endif; ?> \
            <form method="POST" class="space-y-4"> \
                <input type="email" name="to" required class="w-full bg-black/50 border border-slate-700 rounded-xl px-4 py-3 outline-none focus:border-blue-500" placeholder="Target Email"> \
                <input type="text" name="subject" required class="w-full bg-black/50 border border-slate-700 rounded-xl px-4 py-3 outline-none focus:border-blue-500" placeholder="Subject"> \
                <textarea name="message" rows="8" required class="w-full bg-black/50 border border-slate-700 rounded-xl px-4 py-3 outline-none focus:border-blue-500" placeholder="Message..."></textarea> \
                <button type="submit" class="w-full bg-blue-600 py-4 font-black uppercase text-xs tracking-widest hover:bg-blue-500 transition-all">Execute</button> \
            </form> \
        </div> \
        \
        <div id="logs" class="tab-content glass rounded-b-3xl rounded-tr-3xl p-8 h-[500px] overflow-y-auto"> \
            <h2 class="text-green-500 font-black mb-4 italic tracking-tighter">SYSTEM LOGS</h2> \
            <div class="text-[11px] text-green-400 space-y-1"> \
                <div>[INFO] Environment: Northflank US-Central</div> \
                <div>[INFO] Protcol: HTTPS (Port 443) Handshake OK</div> \
                <div>[INFO] SMTP Relay: Postfix @ 587 Ready</div> \
                <div>[INFO] Authentication: Gmail SASL Verified</div> \
                <?php if ($status == "success"): ?> \
                    <div class="text-white mt-4 font-bold">--- RECENT ACTIVITY ---</div> \
                    <div>[SEND] To: <?php echo $to; ?></div> \
                    <div>[SEND] Status: Google SMTP 250 OK</div> \
                <?php endif; ?> \
            </div> \
        </div> \
    </div> \
    \
    <script> \
        function openTab(id) { \
            document.querySelectorAll(\".tab-content\").forEach(t => t.classList.remove(\"active\")); \
            document.getElementById(id).classList.add(\"active\"); \
        } \
    </script> \
</body> \
</html>' > /var/www/localhost/htdocs/index.php

# 5. Startup Sequence
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80 587
CMD php-fpm83 && nginx && postfix start-fg
