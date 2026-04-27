FROM alpine:3.19

# 1. INSTALL STACK
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    php82-session php82-curl \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. CONFIGS
RUN sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/g' /etc/php82/php-fpm.d/www.conf
RUN cat > /etc/nginx/http.d/default.conf <<'EOF'
server {
    listen 80;
    root /var/www/localhost/htdocs;
    index index.php;
    location / { try_files $uri $uri/ /index.php?$args; }
    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
EOF

RUN cat > /etc/supervisord.conf <<'EOF'
[supervisord]
user=root
nodaemon=true
logfile=/dev/stdout
logfile_maxbytes=0
[program:php-fpm]
command=php-fpm82 -F
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
[program:nginx]
command=nginx -g "daemon off;"
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

# 3. MODERN RESPONSIVE UI CODE
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
session_start();
$log = 'registry.json';
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d')])); }
$reg = json_decode(file_get_contents($log), true);

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://142.251.10.108:465', $e, $s, 10, STREAM_CLIENT_CONNECT, $ctx);
    if ($sock) {
        fwrite($sock, "EHLO relay\r\nAUTH LOGIN\r\n".base64_encode('pyypl2005@gmail.com')."\r\n".base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\nRCPT TO: <$to>\r\nDATA\r\nFrom: $name <v@q.io>\r\nSubject: $sub\r\nContent-Type: text/html\r\n\r\n$msg\r\n.\r\nQUIT\r\n");
        fclose($sock);
        $reg['today']++; file_put_contents($log, json_encode($reg));
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MASTERSYNC</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { background: #050505; color: #fff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
        .card { background: #0f0f0f; width: 100%; max-width: 450px; padding: 40px; border-radius: 24px; border: 1px solid #1a1a1a; box-shadow: 0 20px 50px rgba(0,0,0,0.5); }
        h1 { font-size: 28px; font-weight: 900; letter-spacing: -1px; margin-bottom: 30px; text-align: center; }
        h1 span { color: #38bdf8; }
        .stats { background: #1a1a1a; padding: 4px 12px; border-radius: 8px; font-size: 14px; margin-left: 10px; vertical-align: middle; }
        input, textarea { width: 100%; padding: 16px; margin-bottom: 15px; background: #000; border: 1px solid #222; border-radius: 12px; color: #fff; font-size: 16px; outline: none; transition: 0.2s; }
        input:focus, textarea:focus { border-color: #38bdf8; box-shadow: 0 0 0 4px rgba(56, 189, 248, 0.1); }
        button { width: 100%; padding: 18px; background: #fff; color: #000; border: none; border-radius: 12px; font-weight: 800; font-size: 16px; cursor: pointer; transition: 0.2s; text-transform: uppercase; letter-spacing: 1px; }
        button:hover { transform: translateY(-2px); background: #38bdf8; color: #fff; }
        button:active { transform: translateY(0); }
    </style>
</head>
<body>
    <div class="card">
        <h1>MASTER<span>SYNC</span> <span class="stats"><?php echo $reg['today']; ?></span></h1>
        <form method="POST">
            <input type="text" name="name" placeholder="FROM NAME" required>
            <input type="email" name="to" placeholder="RECIPIENT EMAIL" required>
            <input type="text" name="sub" placeholder="SUBJECT LINE" required>
            <textarea name="msg" placeholder="MESSAGE BODY (HTML SUPPORTED)" rows="5" required></textarea>
            <button type="submit">Execute Protocol</button>
        </form>
    </div>
</body>
</html>
EOF

# 4. PERMISSIONS
RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
