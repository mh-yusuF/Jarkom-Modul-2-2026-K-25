#!/bin/bash

apt update
apt install -y php libapache2-mod-php

mkdir -p /var/www/eternal

cat > /var/www/eternal/index.php << 'EOF'
<?php
echo "<h1>ETERNAL AREA</h1>";
echo "<p>PHP berhasil dijalankan</p>";
echo "<p>Waktu Server: ".date('Y-m-d H:i:s')."</p>";
?>
EOF

cat > /etc/apache2/sites-available/000-default.conf << 'EOF'
<VirtualHost *:80>

    RewriteEngine On

    # Jangan redirect /eternal
    RewriteCond %{REQUEST_URI} ^/eternal(/.*)?$ [NC]
    RewriteRule ^ - [L]

    RewriteCond %{HTTP_HOST} ^penny\.zhari\.yusuf\.com$ [NC]
    RewriteRule ^(.*)$ http://www.zhari.yusuf.com$1 [R=301,L]

    RewriteCond %{HTTP_HOST} ^10\.75\.3\.10$
    RewriteRule ^(.*)$ http://www.zhari.yusuf.com$1 [R=301,L]

    ProxyPreserveHost On

    ProxyPass /admin !
    ProxyPass /eternal !

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

    Alias /eternal /var/www/eternal

    <Directory /var/www/eternal>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

</VirtualHost>
EOF

service apache2 restart