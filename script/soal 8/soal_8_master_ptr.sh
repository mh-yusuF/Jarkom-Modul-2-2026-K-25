#!/bin/bash

DOMAIN="zhari.yusuf.com"
REV_ZONE="75.10.in-addr.arpa"
FWD_FILE="/etc/bind/db.$DOMAIN"
REV_FILE="/etc/bind/db.75.10"
IP_PRAB="10.75.1.10"
IP_TEDD="10.75.1.11"
IP_PENNY="10.75.3.1"
SERIAL=$(date +%Y%m%d%H)

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

echo "[3] named.conf.local (forward + reverse)..."
cat << EOF > /etc/bind/named.conf.local || fail "gagal tulis named.conf.local"
zone "$DOMAIN" {
    type master;
    file "$FWD_FILE";
    allow-transfer { $IP_TEDD; };
    notify yes;
    also-notify { $IP_TEDD; };
};

zone "$REV_ZONE" {
    type master;
    file "$REV_FILE";
    allow-transfer { $IP_TEDD; };
    notify yes;
    also-notify { $IP_TEDD; };
};
EOF

echo "[4] Forward zone..."
cat << EOF > "$FWD_FILE" || fail "gagal tulis $FWD_FILE"
\$TTL    604800
@       IN      SOA     prab.$DOMAIN. root.$DOMAIN. (
                        $SERIAL   ; Serial
                         604800   ; Refresh
                          86400   ; Retry
                        2419200   ; Expire
                         604800 ) ; Negative Cache TTL
;
@       IN      NS      prab.$DOMAIN.
@       IN      NS      tedd.$DOMAIN.
@       IN      A       $IP_PENNY
prab    IN      A       $IP_PRAB
tedd    IN      A       $IP_TEDD

alpa    IN      A       10.75.4.10
beta    IN      A       10.75.4.11
gamma   IN      A       10.75.4.12
delta   IN      A       10.75.5.10
epsilon IN      A       10.75.5.11
abbey   IN      A       10.75.2.10
penny   IN      A       10.75.3.1
obladi  IN      A       10.75.1.20
desmond IN      A       10.75.1.21
oblada  IN      A       10.75.1.30
molly   IN      A       10.75.1.31

vault   IN      A       10.75.1.12
vault   IN      A       10.75.1.13
core    IN      A       10.75.1.14
core    IN      A       10.75.1.15

www     IN      CNAME   penny.$DOMAIN.
static  IN      CNAME   abbey.$DOMAIN.
EOF

echo "[5] Reverse zone..."
cat << EOF > "$REV_FILE" || fail "gagal tulis $REV_FILE"
\$TTL    604800
@   IN  SOA prab.$DOMAIN. root.$DOMAIN. (
                  $SERIAL   ; Serial
                   604800   ; Refresh
                    86400   ; Retry
                  2419200   ; Expire
                   604800 ) ; Negative Cache TTL

@   IN  NS  prab.$DOMAIN.
@   IN  NS  tedd.$DOMAIN.

; Format: <oktet4>.<oktet3>  (zone 75.10 = 10.75.x.x)
10.1    IN  PTR prab.$DOMAIN.
11.1    IN  PTR tedd.$DOMAIN.
12.1    IN  PTR vault.$DOMAIN.
13.1    IN  PTR vault.$DOMAIN.
14.1    IN  PTR core.$DOMAIN.
15.1    IN  PTR core.$DOMAIN.
20.1    IN  PTR obladi.$DOMAIN.
21.1    IN  PTR desmond.$DOMAIN.
30.1    IN  PTR oblada.$DOMAIN.
31.1    IN  PTR molly.$DOMAIN.
10.2    IN  PTR abbey.$DOMAIN.
1.3     IN  PTR penny.$DOMAIN.
10.4    IN  PTR alpa.$DOMAIN.
11.4    IN  PTR beta.$DOMAIN.
12.4    IN  PTR gamma.$DOMAIN.
10.5    IN  PTR delta.$DOMAIN.
11.5    IN  PTR epsilon.$DOMAIN.
EOF

chown root:bind "$FWD_FILE" "$REV_FILE" || fail "chown gagal"
chmod 644 "$FWD_FILE" "$REV_FILE"       || fail "chmod gagal"

echo "[6] Validasi..."
named-checkconf || fail "named.conf error"
named-checkzone "$DOMAIN" "$FWD_FILE" || fail "forward zone error"
named-checkzone "$REV_ZONE" "$REV_FILE" || fail "reverse zone error"

echo "[7] Restart + verifikasi..."
service bind9 restart || fail "restart bind9 gagal"
sleep 2
service bind9 status >/dev/null 2>&1 || fail "bind9 tidak berjalan"

R1=$(dig +short -x 10.75.1.10 @127.0.0.1)
echo "$R1" | grep -q "prab.$DOMAIN." || fail "PTR 10.75.1.10 tidak terjawab (hasil: '$R1')"

R2=$(dig +short prab.$DOMAIN @127.0.0.1)
echo "$R2" | grep -q "$IP_PRAB" || fail "A record prab tidak terjawab (hasil: '$R2')"

echo "DNS Master + PTR (prab) berhasil dan terverifikasi!"