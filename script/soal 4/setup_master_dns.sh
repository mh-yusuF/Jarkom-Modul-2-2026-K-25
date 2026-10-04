#!/bin/bash

DOMAIN="zhari.yusuf.com"
IP_PRAB="10.75.1.10" # Sesuaikan dengan IP prab
IP_TEDD="10.75.1.11" # Sesuaikan dengan IP tedd
IP_PENNY="10.75.3.1" # IP penny (apex)

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

echo "[4] Mengonfigurasi named.conf.local (Zone Definition)..."
cat <<EOF > /etc/bind/named.conf.local
zone "$DOMAIN" {
    type master;
    file "/etc/bind/db.$DOMAIN";
    allow-transfer { $IP_TEDD; };
    notify yes;
};
EOF

echo "[5] Membuat File Zone Record (/etc/bind/db.$DOMAIN)..."
cat <<EOF > /etc/bind/db.$DOMAIN
;
; BIND data file for local loopback interface
;
\$TTL    604800
@       IN      SOA     prab.$DOMAIN. root.$DOMAIN. (
                              2        ; Serial
                         604800        ; Refresh
                          86000        ; Retry
                        2419200        ; Expire
                         604800 )      ; Negative Cache TTL
;
@       IN      NS      prab.$DOMAIN.
@       IN      NS      tedd.$DOMAIN.
@       IN      A       $IP_PENNY
prab    IN      A       $IP_PRAB
tedd    IN      A       $IP_TEDD
EOF

echo "[6] Merestart layanan BIND9..."
service bind9 restart

echo "✅ Setup Master DNS (Prab) Selesai!"