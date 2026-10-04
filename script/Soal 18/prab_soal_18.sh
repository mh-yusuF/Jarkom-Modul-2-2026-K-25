#!/bin/bash

ZONE="/etc/bind/db.zhari.yusuf.com"

echo "[+] Backup file zona..."
cp $ZONE ${ZONE}.bak

echo "[+] Mengubah record abbey menjadi IP fiktif dengan TTL 15 detik..."

sed -i '/abbey[[:space:]]*IN[[:space:]]*A/c\abbey   IN      15      A       192.168.123.123' $ZONE

echo "[+] Menaikkan serial SOA..."

OLD_SERIAL=$(grep Serial $ZONE | awk '{print $1}')
NEW_SERIAL=$((OLD_SERIAL + 1))

sed -i "s/$OLD_SERIAL/$NEW_SERIAL/" $ZONE

echo "[+] Validasi zona..."

named-checkzone zhari.yusuf.com $ZONE

echo "[+] Restart bind9..."
service bind9 restart

echo
echo "=== HASIL RECORD ABBEY ==="
dig @127.0.0.1 abbey.zhari.yusuf.com

echo
echo "=== HASIL SOA ==="
dig @127.0.0.1 zhari.yusuf.com SOA