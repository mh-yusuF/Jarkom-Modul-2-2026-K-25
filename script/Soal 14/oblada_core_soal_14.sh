#!/bin/bash

cat > /etc/nginx/conf.d/realip.conf << 'EOF'
set_real_ip_from 10.75.2.10;

real_ip_header X-Real-IP;

real_ip_recursive on;
EOF

service nginx restart