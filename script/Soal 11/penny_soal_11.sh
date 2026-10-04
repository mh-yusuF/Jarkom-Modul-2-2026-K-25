#!/bin/bash

apt update
apt install -y apache2

a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests
a2enmod headers

cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>

    ProxyPreserveHost On

    <Proxy "balancer://vaultcluster">
        BalancerMember http://10.75.1.12
        BalancerMember http://10.75.1.13
    </Proxy>

    ProxyPass "/" "balancer://vaultcluster/"
    ProxyPassReverse "/" "balancer://vaultcluster/"

    RequestHeader set X-Real-IP %{REMOTE_ADDR}s

</VirtualHost>
EOF

service apache2 restart