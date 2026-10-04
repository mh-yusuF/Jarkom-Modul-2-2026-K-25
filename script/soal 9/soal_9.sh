#!/bin/bash

DOMAIN="zhari.yusuf.com"
WEB_HOST="vault.$DOMAIN"
ARSIP_DIR="/var/www/html/arsip"

fail() { echo "GAGAL: $1" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "harus dijalankan sebagai root"

echo "[0] Sinkronisasi waktu..."
D=$( exec 3<>/dev/tcp/deb.debian.org/80 \
     && printf 'HEAD / HTTP/1.0\r\nHost: deb.debian.org\r\n\r\n' >&3 \
     && grep -i -m1 '^date:' <&3 | cut -d' ' -f2- | tr -d '\r' )
[ -n "$D" ] || fail "tidak bisa ambil waktu dari internet (cek koneksi/DNS)"
date -s "$D" >/dev/null || fail "gagal set waktu"
echo "Waktu sekarang (UTC): $(date -u)"

echo "[1] Install Apache..."
apt-get update && apt-get install -y apache2 curl || fail "install apache2 gagal"

echo "[2] Buat folder /arsip dan file contoh..."
mkdir -p "$ARSIP_DIR" || fail "gagal buat $ARSIP_DIR"
echo "Dokumen 1 - arsip vault" > "$ARSIP_DIR/dokumen1.txt"
echo "Dokumen 2 - arsip vault" > "$ARSIP_DIR/dokumen2.txt"
echo "Laporan - arsip vault"   > "$ARSIP_DIR/laporan.txt"
rm -f "$ARSIP_DIR/index.html"    # index.html akan menutupi directory listing
chown -R www-data:www-data "$ARSIP_DIR"
chmod -R 755 "$ARSIP_DIR"

echo "[3] Konfigurasi Apache (autoindex + ServerName)..."
cat << EOF > /etc/apache2/conf-available/arsip.conf || fail "gagal tulis arsip.conf"
ServerName $WEB_HOST

<Directory $ARSIP_DIR>
    Options +Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
EOF

a2enmod autoindex >/dev/null 2>&1
a2enconf arsip    >/dev/null 2>&1 || fail "a2enconf gagal"

apachectl configtest || fail "konfigurasi apache error"

echo "[4] Restart + verifikasi..."
service apache2 restart || fail "restart apache2 gagal"
sleep 2
service apache2 status >/dev/null 2>&1 || fail "apache2 tidak berjalan"

OUT=$(curl -s -H "Host: $WEB_HOST" http://127.0.0.1/arsip/)
echo "$OUT" | grep -q "Index of /arsip" || fail "directory listing tidak muncul"
echo "$OUT" | grep -q "dokumen1.txt"    || fail "file di /arsip tidak terlihat di listing"

echo "Web vault berhasil, autoindex /arsip/ aktif!"