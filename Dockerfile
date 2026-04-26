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
    index index.php; \
    location / { try_files $uri $uri/ =404; } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 4. BAKE THE UI DIRECTLY INTO THE DOCKERFILE
RUN echo '<?php \
$status = ""; \
if ($_SERVER["REQUEST_METHOD"] == "POST") { \
    $to = filter_var($_POST["to"], FILTER_SANITIZE_EMAIL); \
    $subject = htmlspecialchars($_POST["subject"]); \
    $message = htmlspecialchars($_POST["message"]); \
    $headers = "From: verified@elite.qzz.io\r\nContent-Type: text/html; charset=UTF-8\r\n"; \
    if (mail($to, $subject, $message, $headers)) { $status = "success"; } else { $status = "error"; } \
} \
?> \
<!DOCTYPE html> \
<html lang="en"> \
<head> \
    <meta charset="UTF-8"> \
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> \
    <title>Elite Relay</title> \
    <script src="https://cdn.tailwindcss.com"></script> \
    <style>body { background: #020617; color: white; font-family: sans-serif; }</style> \
</head> \
<body class="min-h-screen flex items-center justify-center p-4"> \
    <div class="bg-slate-900/50 backdrop-blur-xl border border-white/10 w-full max-w-md rounded-[2rem] p-8 shadow-2xl"> \
        <div class="flex items-center space-x-3 mb-8"> \
            <div class="h-10 w-10 bg-blue-600 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/50"> \
                <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg> \
            </div> \
            <h1 class="text-xl font-bold tracking-tighter">ELITE<span class="text-blue-500">RELAY</span></h1> \
        </div> \
        <?php if ($status == "success"): ?> \
            <div class="mb-6 p-4 bg-green-500/10 border border-green-500/50 rounded-2xl text-green-400 text-xs text-center">Transmission Successful</div> \
        <?php endif; ?> \
        <form method="POST" class="space-y-5"> \
            <input type="email" name="to" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 outline-none focus:border-blue-500 transition-all" placeholder="Destination Email"> \
            <input type="text" name="subject" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 outline-none focus:border-blue-500 transition-all" placeholder="Subject"> \
            <textarea name="message" rows="4" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 outline-none focus:border-blue-500 transition-all resize-none" placeholder="Message content..."></textarea> \
            <button type="submit" class="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-5 rounded-2xl shadow-lg shadow-blue-600/20 transition-all uppercase tracking-widest text-xs">Execute Deploy</button> \
        </form> \
    </div> \
</body> \
</html>' > /var/www/localhost/htdocs/index.php

# 5. Finalize permissions and ports
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80 587

# 6. Start PHP, Nginx, and Postfix
CMD php-fpm83 && nginx && postfix start-fg
