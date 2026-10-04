#!/bin/bash

a2enmod rewrite

cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>

    RewriteEngine On

    RewriteCond %{HTTP_HOST} ^penny\.zhari\.yusuf\.com$ [NC]
    RewriteRule ^(.*)$ http://www.zhari.yusuf.com$1 [R=301,L]

    RewriteCond %{HTTP_HOST} ^10\.75\.3\.10$
    RewriteRule ^(.*)$ http://www.zhari.yusuf.com$1 [R=301,L]

    ProxyPreserveHost On

    ProxyPass /admin !

    <Proxy "balancer://vaultcluster">
        BalancerMember http://10.75.1.12
        BalancerMember http://10.75.1.13
    </Proxy>

    ProxyPass "/" "balancer://vaultcluster/"
    ProxyPassReverse "/" "balancer://vaultcluster/"

    RequestHeader set X-Real-IP %{REMOTE_ADDR}s

    Alias /admin /var/www/html/admin

    <Directory /var/www/html/admin>
        AuthType Basic
        AuthName "Restricted Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>

</VirtualHost>
EOF

service apache2 restart