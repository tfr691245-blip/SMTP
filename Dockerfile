FROM alpine:3.19

# 1. INSTALL STACK
RUN apk add --no-cache \
    nginx php82 php82-fpm php82-openssl php82-mbstring php82-json \
    php82-session php82-curl \
    tzdata supervisor && mkdir -p /run/nginx /var/www/localhost/htdocs /var/log/supervisor

# 2. PERMANENT CONFIGS
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
[program:php-fpm]
command=php-fpm82 -F
[program:nginx]
command=nginx -g "daemon off;"
EOF

# 3. ADVANCED UI + LIMIT LOGIC
RUN cat > /var/www/localhost/htdocs/index.php <<'EOF'
<?php
session_start();
$log = 'registry.json';
$max = 99; 
if(!file_exists($log)) { file_put_contents($log, json_encode(['today'=>0,'date'=>date('Y-m-d'),'blocked'=>false])); }
$reg = json_decode(file_get_contents($log), true);
if($reg['date'] != date('Y-m-d')) { $reg = ['today'=>0,'date'=>date('Y-m-d'),'blocked'=>false]; }

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_GET['ajax'])) {
    header('Content-Type: application/json');
    if($reg['today'] >= $max || $reg['blocked']) { echo json_encode(['status'=>'error', 'msg'=>'Limit Reached']); exit; }

    $to = $_POST['to']; $name = $_POST['name']; $sub = $_POST['sub']; $msg = $_POST['msg'];
    $ctx = stream_context_create(['ssl' => ['verify_peer'=>false,'verify_peer_name'=>false]]);
    $sock = @stream_socket_client('ssl://142.251.10.108:465', $e, $s, 5, STREAM_CLIENT_CONNECT, $ctx);
    
    if ($sock) {
        fwrite($sock, "EHLO relay\r\nAUTH LOGIN\r\n".base64_encode('pyypl2005@gmail.com')."\r\n".base64_encode('gnrbyxyyjxyoaljv')."\r\n");
        $res = fread($sock, 1024);
        if (strpos($res, '535') !== false || strpos($res, '454') !== false) {
            $reg['blocked'] = true; file_put_contents($log, json_encode($reg));
            echo json_encode(['status'=>'error', 'msg'=>'Google Blocked']); exit;
        }
        fwrite($sock, "MAIL FROM: <pyypl2005@gmail.com>\r\nRCPT TO: <$to>\r\nDATA\r\nFrom: $name <v@q.io>\r\nSubject: $sub\r\nContent-Type: text/html\r\n\r\n$msg\r\n.\r\nQUIT\r\n");
        fclose($sock);
        $reg['today']++; file_put_contents($log, json_encode($reg));
        echo json_encode(['status'=>'success', 'left'=>($max - $reg['today'])]);
    } else { echo json_encode(['status'=>'error', 'msg'=>'SMTP Offline']); }
    exit;
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>MASTERSYNC ELITE</title>
    <style>
        :root { --accent: #38bdf8; --bg: #050505; --card: #121212; }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Inter', sans-serif; }
        body { background: var(--bg); color: #fff; display: flex; align-items: center; justify-content: center; min-height: 100vh; overflow: hidden; }
        .card { width: 95%; max-width: 440px; background: var(--card); padding: 40px 30px; border-radius: 32px; border: 1px solid #222; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.8); position: relative; }
        .header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px; }
        h1 { font-size: 26px; font-weight: 800; letter-spacing: -1px; }
        h1 span { color: var(--accent); }
        .badge { background: rgba(56, 189, 248, 0.1); color: var(--accent); padding: 5px 12px; border-radius: 12px; font-size: 13px; font-weight: 700; border: 1px solid rgba(56, 189, 248, 0.2); }
        .input-group { margin-bottom: 16px; }
        input, textarea { width: 100%; padding: 16px; background: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 16px; color: #fff; font-size: 16px; transition: 0.2s ease; outline: none; }
        input:focus, textarea:focus { border-color: var(--accent); background: #222; }
        button { width: 100%; padding: 18px; background: #fff; color: #000; border: none; border-radius: 18px; font-weight: 800; font-size: 16px; cursor: pointer; transition: 0.3s; margin-top: 10px; }
        button:hover { background: var(--accent); color: #fff; transform: translateY(-2px); }
        button:active { transform: translateY(0); }
        #toast { position: fixed; bottom: 30px; left: 50%; transform: translateX(-50%); padding: 15px 30px; border-radius: 20px; font-weight: 700; display: none; z-index: 1000; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    </style>
</head>
<body>
    <div id="toast"></div>
    <div class="card">
        <div class="header">
            <h1>MASTER<span>SYNC</span></h1>
            <div class="badge">LIMIT: <span id="rem"><?php echo $reg['blocked'] ? '0' : ($max - $reg['today']); ?></span></div>
        </div>
        <form id="f">
            <input type="text" name="name" placeholder="Sender Identity" required class="input-group">
            <input type="email" name="to" placeholder="Target Destination" required class="input-group">
            <input type="text" name="sub" placeholder="Subject Protocol" required class="input-group">
            <textarea name="msg" placeholder="Encrypted Payload (HTML)" rows="5" required class="input-group"></textarea>
            <button type="submit" id="b">INITIALIZE SEND</button>
        </form>
    </div>
    <script>
        const f = document.getElementById('f'), b = document.getElementById('b'), r = document.getElementById('rem'), t = document.getElementById('toast');
        f.onsubmit = async (e) => {
            e.preventDefault(); b.disabled = true; b.innerText = 'SYNCHRONIZING...';
            try {
                const res = await fetch('?ajax=1', { method: 'POST', body: new FormData(f) });
                const d = await res.json();
                if(d.status === 'success') {
                    r.innerText = d.left; notify('PROTOCOL SUCCESS', '#22c55e'); f.reset();
                } else { 
                    notify(d.msg.toUpperCase(), '#ef4444'); 
                    if(d.msg.includes('Limit')) r.innerText = '0';
                }
            } catch (e) { notify('NETWORK ERROR', '#ef4444'); }
            b.disabled = false; b.innerText = 'INITIALIZE SEND';
        };
        function notify(txt, c) { t.innerText = txt; t.style.background = c; t.style.display = 'block'; setTimeout(()=>t.style.display='none', 3000); }
    </script>
</body>
</html>
EOF

RUN touch /var/www/localhost/htdocs/registry.json && chmod -R 777 /var/www/localhost/htdocs
EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
