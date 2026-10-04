#!/bin/bash

apt update
apt install -y apache2 apache2-utils

mkdir -p /var/www/html/admin

cat > /var/www/html/admin/index.html << 'EOF'
<html>
<body>
<h1>ADMIN AREA</h1>
<p>Dokumen Rahasia Sindikat</p>
</body>
</html>
EOF

htpasswd -cb /etc/apache2/.htpasswd prabs pakar_pinter_jadi_gob***

cat > /etc/apache2/conf-available/admin-auth.conf << 'EOF'
ProxyPass /admin !

Alias /admin /var/www/html/admin

<Directory /var/www/html/admin>
    AuthType Basic
    AuthName "Restricted Area"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Directory>
EOF

a2enconf admin-auth

service apache2 restart