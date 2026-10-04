#!/bin/bash

echo "[+] Meminta zone transfer ulang dari Prab..."

rndc retransfer zhari.yusuf.com

echo "[+] Restart bind9..."
service bind9 restart

echo
echo "=== CEK SOA ==="
dig @127.0.0.1 zhari.yusuf.com SOA

echo
echo "=== CEK RECORD ABBEY =a=="
dig @127.0.0.1 abbey.zhari.yusuf.com

echo
echo "=== CEK FILE SLAVE ==="

named-compilezone -f raw -F text \
-o /tmp/zone.txt \
zhari.yusuf.com \
/var/cache/bind/db.zhari.yusuf.com

grep abbey /tmp/zone.txt