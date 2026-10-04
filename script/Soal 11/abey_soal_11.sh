#!/bin/bash

apt update
apt install -y nginx

cat > /etc/nginx/sites-available/default << 'EOF'
upstream corecluster {
    server 10.75.1.14;
    server 10.75.1.15;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://corecluster;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

nginx -t
service nginx restart
