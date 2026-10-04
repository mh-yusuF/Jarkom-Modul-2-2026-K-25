#!/bin/bash

echo "[*] Konfigurasi Soal 19 - Outbound CNAME"

ZONE="/etc/bind/db.zhari.yusuf.com"

# Tambahkan record jika belum ada
grep -q "^outbound" $ZONE || \
echo "outbound IN CNAME http.badssl.com." >> $ZONE

# Naikkan serial
SERIAL=$(grep Serial $ZONE | awk '{print $1}')
NEW_SERIAL=$((SERIAL+1))
sed -i "s/$SERIAL[[:space:]]*; Serial/$NEW_SERIAL   ; Serial/" $ZONE

# Validasi zone
named-checkzone zhari.yusuf.com $ZONE

# Restart bind
service bind9 restart

echo "[✓] Soal 19 selesai"