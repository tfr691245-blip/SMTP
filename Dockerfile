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
    && /usr/bin/newaliases

# 3. Configure Nginx
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

# 4. BAKE THE MODERN UI DIRECTLY
# Change 'admin123' to your preferred password below
RUN echo '<?php \
$ACCESS_KEY = "admin123"; \
$auth = isset($_POST["key"]) && $_POST["key"] == $ACCESS_KEY; \
$status = ""; \
if ($auth && isset($_POST["to"])) { \
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"> \
    <title>Elite Relay</title> \
    <script src="https://cdn.tailwindcss.com"></script> \
    <style>body { background: #020617; font-family: sans-serif; }</style> \
</head> \
<body class="min-h-screen flex items-center justify-center p-4"> \
    <div class="bg-slate-900/50 backdrop-blur-xl border border-white/10 w-full max-w-md rounded-[2.5rem] p-8 shadow-2xl"> \
        <div class="flex items-center space-x-3 mb-8"> \
            <div class="h-12 w-12 bg-blue-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/50"> \
                <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg> \
            </div> \
            <h1 class="text-2xl font-black tracking-tighter italic text-white uppercase">Elite<span class="text-blue-500">Relay</span></h1> \
        </div> \
        <?php if (!$auth): ?> \
            <form method="POST" class="space-y-6"> \
                <input type="password" name="key" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-6 py-4 text-center text-white outline-none focus:border-blue-500 transition-all" placeholder="Enter Access Key"> \
                <button type="submit" class="w-full bg-white text-black font-black py-4 rounded-2xl hover:bg-blue-400 transition-all uppercase tracking-widest text-xs">Unlock</button> \
            </form> \
        <?php else: ?> \
            <?php if ($status == "success"): ?><div class="mb-4 p-3 bg-green-500/20 border border-green-500/50 rounded-xl text-green-400 text-xs text-center">Deploy Successful</div><?php endif; ?> \
            <form method="POST" class="space-y-4"> \
                <input type="hidden" name="key" value="<?php echo $_POST["key"]; ?>"> \
                <input type="email" name="to" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-white outline-none focus:border-blue-500 transition-all" placeholder="Target Email"> \
                <input type="text" name="subject" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-white outline-none focus:border-blue-500 transition-all" placeholder="Subject"> \
                <textarea name="message" rows="4" required class="w-full bg-slate-950 border border-slate-800 rounded-2xl px-5 py-4 text-white outline-none focus:border-blue-500 transition-all resize-none" placeholder="Message content..."></textarea> \
                <button type="submit" class="w-full bg-blue-600 text-white font-bold py-5 rounded-2xl shadow-lg shadow-blue-600/20 transition-all uppercase tracking-widest text-xs">Execute Deploy</button> \
            </form> \
        <?php endif; ?> \
    </div> \
</body> \
</html>' > /var/www/localhost/htdocs/index.php

# 5. Final Permissions and Startup
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80 587
CMD php-fpm83 && nginx && postfix start-fg
