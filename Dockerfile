# Master Official Kernel - Google Sync Edition (2026)
FROM alpine:3.19

# 1. Performance Stack
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    tzdata && mkdir -p /run/nginx /var/www/localhost/htdocs /var/lib/sys-kernel \
    && chown -R nginx:nginx /var/lib/sys-kernel

# 2. Optimized Nginx Config
RUN echo 'server { \
    listen 80; \
    root /var/www/localhost/htdocs; \
    index index.php; \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/http.d/default.conf

# 3. Kernel Sync HUD (Google Direct Check)
RUN cat <<'EOF' > /var/www/localhost/htdocs/index.php
<?php
$smtp_host = 'ssl://142.251.10.108'; 
$user = 'pyypl2005@gmail.com';
$pass = 'gnrbyxyyjxyoaljv';
$alias = 'verified@elite.qzz.io';
$kernel_file = '/var/lib/sys-kernel/registry.json';
$safe_limit = 99; 

// KERNEL PERSISTENCE
$reg = file_exists($kernel_file) ? json_decode(file_get_contents($kernel_file), true) : ['history' => [], 'today' => 0, 'stamp' => date('Y-m-d')];
if ($reg['stamp'] !== date('Y-m-d')) {
    array_unshift($reg['history'], $reg['today']);
    $reg['history'] = array_slice($reg['history'], 0, 8);
    $reg['today'] = 0;
    $reg['stamp'] = date('Y-m-d');
}

$status = "IDLE";
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if ($reg['today'] >= $safe_limit) { $status = "SYSTEM_HALT_LIMIT"; }
    else {
        $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
        $headers = ["From: $name <$alias>", "To: $to", "Subject: $sub", "MIME-Version: 1.0", "Content-Type: text/html; charset=UTF-8"];
        $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
        $sock = @stream_socket_client($smtp_host.':465', $errno, $errstr, 5, STREAM_CLIENT_CONNECT, $ctx);
        if ($sock) {
            fread($sock, 512); fwrite($sock, "EHLO kernel.sync\r\n"); fread($sock, 512);
            fwrite($sock, "AUTH LOGIN\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($user)."\r\n"); fread($sock, 512);
            fwrite($sock, base64_encode($pass)."\r\n"); fread($sock, 512);
            fwrite($sock, "MAIL FROM: <$user>\r\n"); fread($sock, 512);
            fwrite($sock, "RCPT TO: <$to>\r\n"); fread($sock, 512);
            fwrite($sock, "DATA\r\n"); fread($sock, 512);
            fwrite($sock, implode("\r\n", $headers) . "\r\n\r\n" . $msg . "\r\n.\r\n");
            fwrite($sock, "QUIT\r\n"); fclose($sock);
            $reg['today']++; file_put_contents($kernel_file, json_encode($reg));
            $status = "INJECTED";
        } else { $status = "NET_TIMEOUT"; }
    }
}
?>
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>KERNEL OFFICIAL SYNC</title><script src="https://cdn.tailwindcss.com"></script>
<style>
    body { background: #02040a; color: #fff; font-family: monospace; display: flex; align-items: center; justify-content: center; height: 100vh; }
    .kernel-container { background: #0d1117; border: 1px solid #30363d; border-radius: 12px; width: 420px; box-shadow: 0 0 50px rgba(0,0,0,0.9); }
    .official-btn { background: #238636; transition: 0.2s; }
    .official-btn:hover { background: #2ea043; }
    input, textarea { background: #010409; border: 1px solid #30363d; border-radius: 6px; color: #c9d1d9; font-size: 12px; width: 100%; padding: 10px; outline: none; }
    input:focus { border-color: #58a6ff; }
</style></head>
<body class="p-4">
    <div class="kernel-container p-6 animate-pulse-slow">
        <div class="flex justify-between items-center mb-6 border-b border-[#30363d] pb-4">
            <div>
                <h1 class="text-xs font-bold text-slate-500 uppercase tracking-widest">Master Kernel v4</h1>
                <p class="text-lg font-black text-white">RELIABILITY: <span class="text-emerald-400">99.9%</span></p>
            </div>
            <a href="https://mail.google.com/mail/u/0/#search/newer_than%3A1d" target="_blank" class="text-[10px] bg-blue-600/20 text-blue-400 border border-blue-400/30 px-3 py-2 rounded-md hover:bg-blue-600 hover:text-white transition-all font-bold">
                OFFICIAL GOOGLE CHECK
            </a>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="bg-[#010409] border border-[#30363d] p-4 rounded-lg">
                <p class="text-[10px] text-slate-500 font-bold mb-1">LOCAL REGISTRY</p>
                <p class="text-xl font-black"><?php echo $reg['today']; ?> <span class="text-slate-700">/ 99</span></p>
            </div>
            <div class="bg-[#010409] border border-[#30363d] p-4 rounded-lg">
                <p class="text-[10px] text-slate-500 font-bold mb-1">SYSTEM STATE</p>
                <p class="text-xs font-black text-emerald-500"><?php echo $status; ?></p>
            </div>
        </div>

        <form method="POST" class="space-y-3">
            <div class="flex gap-2">
                <input name="name" placeholder="Sender Name" required>
                <input name="to" placeholder="Target Email" type="email" required>
            </div>
            <input name="sub" placeholder="Subject Line" required>
            <textarea name="msg" placeholder="HTML Payload..." class="h-24 resize-none"></textarea>
            <button class="w-full official-btn text-white font-bold py-3 rounded-md text-sm uppercase tracking-widest mt-2">Execute Official Injection</button>
        </form>
        
        <p class="text-[9px] text-slate-600 mt-4 text-center">Click 'OFFICIAL GOOGLE CHECK' to sync with your actual search results.</p>
    </div>
</body></html>
EOF

# 4. Kernel Persistence
RUN chown -R nginx:nginx /var/www/localhost/htdocs /var/lib/sys-kernel
EXPOSE 80
CMD php-fpm82 && nginx -g "daemon off;"
