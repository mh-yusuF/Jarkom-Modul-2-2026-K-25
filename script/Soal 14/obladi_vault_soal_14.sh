#!/bin/bash

a2enmod remoteip

cat > /etc/apache2/conf-available/realip.conf << 'EOF'
RemoteIPHeader X-Real-IP

RemoteIPTrustedProxy 10.75.3.10
EOF

a2enconf realip

service apache2 restart