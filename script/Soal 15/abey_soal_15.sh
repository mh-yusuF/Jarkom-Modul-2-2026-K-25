#!/bin/bash

mkdir -p /var/www/orion

cat > /var/www/orion/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ORION AREA</title>
</head>
<body>
    <h1>ORION AREA</h1>
    <p>Konten statis dari Abbey</p>
</body>
</html>
EOF

cat > /etc/nginx/conf.d/redirect-abbey.conf << 'EOF'
server {
    listen 80;

    server_name abbey.zhari.yusuf.com 10.75.2.10;

    location /orion/ {
        alias /var/www/orion/;
        index index.html;
    }

    location / {
        return 302 http://static.zhari.yusuf.com$request_uri;
    }
}
EOF

nginx -t
service nginx restart