#!/bin/bash

apt update
apt install -y apache2

cat > /var/www/html/index.html << 'EOF'
<html>
<body>
<h1>SERVER MOLLY</h1>
</body>
</html>
EOF

service apache2 restart