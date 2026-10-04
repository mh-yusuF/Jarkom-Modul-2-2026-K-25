#!/bin/bash

DOMAIN="zhari.yusuf.com"
IP_PRAB="10.75.1.10" # Sesuaikan dengan IP prab (Master)

echo "[1] Menginstal BIND9 dan BIND9utils..."
apt-get update
apt-get install -y bind9 bind9utils

echo "[2] Membuat symlink init.d BIND9 (jika belum ada)..."
if [ ! -e /etc/init.d/bind9 ] && [ -e /etc/init.d/named ]; then
    ln -s /etc/init.d/named /etc/init.d/bind9
fi

echo "[3] Mengonfigurasi named.conf.options (Forwarders)..."
cat <<EOF > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    forwarders {
        192.168.122.1;
    };
    dnssec-validation auto;
    listen-on { any; };
    allow-query { any; };
};
EOF

echo "[4] Mengonfigurasi named.conf.local (Slave Zone Definition)..."
cat <<EOF > /etc/bind/named.conf.local
zone "$DOMAIN" {
    type slave;
    file "/var/cache/bind/db.$DOMAIN";
    masters { $IP_PRAB; };
};
EOF

echo "[5] Merestart layanan BIND9..."
service bind9 restart

echo "✅ Setup Slave DNS (Tedd) Selesai!"