FROM alpine:3.19

# 1. Official Kernel Stack
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json php82-imap \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs

# 2. Kill Automatic Retries (Nginx Config)
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    proxy_next_upstream off; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
        fastcgi_read_timeout 60s; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. Real-Time Sync HUD + Anti-Double Fire
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
session_start();
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$smtp_host = 'ssl://142.251.10.108';

// REAL KERNEL SYNC
function get_official_count($u, $p) {
    $mbox = @imap_open("{imap.gmail.com:993/imap/ssl}[Gmail]/Sent Mail", $u, $p);
    if (!$mbox) return "OFFLINE";
    $since = date("d-M-Y", strtotime("-1 day"));
    $emails = imap_search($mbox, 'SINCE "'.$since.'"');
    $count = $emails ? count($emails) : 0;
    imap_close($mbox);
    return $count;
}

$official_count = get_official_count($user, $pass);

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['token'])) {
    // ANTI-GHOST LOCK
    if ($_POST['token'] !== $_SESSION['last_token']) {
        $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
        $headers = ["From: $name <verified@elite.qzz.io>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
        
        $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
        $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 10, STREAM_CLIENT_CONNECT, $ctx);
        
        if ($sock) {
            fread($sock, 512); fwrite($sock, "EHLO relay\r\n"); fread($sock, 512);
            fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
            fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
            fwrite($sock, "DATA\r\n"); fread($sock, 512);
            fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
            fwrite($sock, "QUIT\r\n"); fclose($sock);
            
            $_SESSION['last_token'] = $_POST['token']; // LOCK TOKEN
            header("Location: index.php?success=1"); exit;
        }
    }
}
$token = bin2hex(random_bytes(16));
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>MASTER KERNEL V6</title>
<script src="https://cdn.tailwindcss.com"></script></head>
<body class="bg-[#020202] text-white font-mono flex items-center justify-center min-h-screen">
    <div class="w-full max-w-md p-10 bg-[#0a0a0a] border border-white/5 rounded-[2.5rem] shadow-2xl">
        <div class="flex justify-between items-start mb-10">
            <h1 class="text-2xl font-black italic">REAL<span class="text-blue-500">SYNC</span></h1>
            <div class="text-right">
                <p class="text-[10px] text-slate-500 font-bold uppercase">Official Sent (24h)</p>
                <p class="text-3xl font-black text-emerald-400"><?php echo $official_count; ?> <span class="text-slate-800 text-sm">/ 99</span></p>
            </div>
        </div>

        <form method="POST" class="space-y-4">
            <input type="hidden" name="token" value="<?php echo $token; ?>">
            <input name="name" placeholder="SENDER" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full outline-none focus:border-blue-500">
            <input name="to" placeholder="RECIPIENT" type="email" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full outline-none focus:border-blue-500">
            <input name="sub" placeholder="SUBJECT" required class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full outline-none focus:border-blue-500">
            <textarea name="msg" placeholder="PAYLOAD..." class="bg-black border border-white/5 p-4 rounded-2xl text-xs w-full h-32 outline-none focus:border-blue-500 resize-none"></textarea>
            
            <button class="w-full bg-white text-black font-black py-4 rounded-2xl hover:bg-blue-600 hover:text-white transition-all uppercase tracking-widest text-xs">Execute Master Fire</button>
        </form>
    </div>
</body></html>
EOF

# 4. Finish
RUN chown -R nginx:nginx /var/www/localhost/htdocs
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
