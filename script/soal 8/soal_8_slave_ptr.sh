#!/bin/bash

DOMAIN="zhari.yusuf.com"
REV_ZONE="75.10.in-addr.arpa"
IP_PRAB="10.75.1.10"

fail() { echo "GAGAL: $1" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "harus dijalankan sebagai root"

echo "[1] Install BIND9..."
apt-get update && apt-get install -y bind9 bind9utils dnsutils || fail "install paket gagal"

if [ ! -e /etc/init.d/bind9 ] && [ -e /etc/init.d/named ]; then
    ln -s /etc/init.d/named /etc/init.d/bind9
fi

echo "[2] named.conf.options..."
cat << EOF > /etc/bind/named.conf.options || fail "gagal tulis named.conf.options"
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

echo "[3] named.conf.local (slave forward + reverse)..."
cat << EOF > /etc/bind/named.conf.local || fail "gagal tulis named.conf.local"
zone "$DOMAIN" {
    type slave;
    file "/var/cache/bind/db.$DOMAIN";
    masters { $IP_PRAB; };
};

zone "$REV_ZONE" {
    type slave;
    file "/var/cache/bind/db.75.10";
    masters { $IP_PRAB; };
};
EOF

named-checkconf || fail "named.conf error"

echo "[4] Restart + tunggu zone transfer..."
service bind9 restart || fail "restart bind9 gagal"
sleep 2
service bind9 status >/dev/null 2>&1 || fail "bind9 tidak berjalan"

OK=0
for i in $(seq 1 10); do
    R1=$(dig +short -x 10.75.1.10 @127.0.0.1)
    R2=$(dig +short prab.$DOMAIN @127.0.0.1)
    if echo "$R1" | grep -q "prab.$DOMAIN." && echo "$R2" | grep -q "$IP_PRAB"; then
        OK=1; break
    fi
    sleep 2
done

[ "$OK" -eq 1 ] || fail "zone transfer belum jalan. Cek: master sudah jalan? port 53 terbuka? allow-transfer benar?"

echo "DNS Slave + PTR (tedd) berhasil, zone ter-transfer dari prab!"