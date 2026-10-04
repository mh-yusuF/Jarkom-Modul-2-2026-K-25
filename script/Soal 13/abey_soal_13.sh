#!/bin/bash

cat > /etc/nginx/conf.d/redirect-abbey.conf << 'EOF'
server {
    listen 80;

    server_name abbey.zhari.yusuf.com 10.75.2.10;

    return 302 http://static.zhari.yusuf.com$request_uri;
}
EOF

nginx -t
service nginx restart