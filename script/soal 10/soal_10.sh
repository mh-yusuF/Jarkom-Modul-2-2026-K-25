#!/bin/bash

DOMAIN="zhari.yusuf.com"
WEB_HOST="core.$DOMAIN"
WEB_ROOT="/var/www/core"

fail() { echo "GAGAL: $1" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "harus dijalankan sebagai root"

echo "[0] Sinkronisasi waktu..."
D=$( exec 3<>/dev/tcp/deb.debian.org/80 \
     && printf 'HEAD / HTTP/1.0\r\nHost: deb.debian.org\r\n\r\n' >&3 \
     && grep -i -m1 '^date:' <&3 | cut -d' ' -f2- | tr -d '\r' )
[ -n "$D" ] || fail "tidak bisa ambil waktu dari internet (cek koneksi/DNS)"
date -s "$D" >/dev/null || fail "gagal set waktu"
echo "Waktu sekarang (UTC): $(date -u)"

echo "[1] Install nginx + PHP-FPM..."
apt-get update && apt-get install -y nginx php-fpm curl || fail "install paket gagal"

PHPV=$(ls /etc/php 2>/dev/null | sort -V | tail -1)
[ -n "$PHPV" ] || fail "versi PHP tidak terdeteksi"
PHP_SVC="php${PHPV}-fpm"
PHP_SOCK="/run/php/php${PHPV}-fpm.sock"
echo "PHP versi $PHPV, service $PHP_SVC"

echo "[2] Buat aplikasi (beranda + profil)..."
mkdir -p "$WEB_ROOT" || fail "gagal buat $WEB_ROOT"

cat << 'EOF' > "$WEB_ROOT/index.php" || fail "gagal tulis index.php"
<?php $host = $_SERVER['HTTP_HOST']; $server = gethostname(); ?>
<!DOCTYPE html>
<html>
<head><title>Beranda</title></head>
<body>
  <h1>Beranda</h1>
  <p>Selamat datang di layanan web dinamis (PHP-FPM + nginx).</p>
  <p>Hostname: <?= htmlspecialchars($host) ?> | Dilayani oleh node: <?= htmlspecialchars($server) ?></p>
  <p>Waktu server: <?= date('Y-m-d H:i:s') ?></p>
  <p><a href="/profil">Lihat Profil</a></p>
</body>
</html>
EOF

cat << 'EOF' > "$WEB_ROOT/profil.php" || fail "gagal tulis profil.php"
<?php $server = gethostname(); ?>
<!DOCTYPE html>
<html>
<head><title>Profil</title></head>
<body>
  <h1>Profil</h1>
  <p>Nama: Zhari Yusuf</p>
  <p>Node: <?= htmlspecialchars($server) ?></p>
  <p>Versi PHP: <?= PHP_VERSION ?></p>
  <p><a href="/">Kembali ke Beranda</a></p>
</body>
</html>
EOF

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"

echo "[3] Konfigurasi nginx (rewrite /profil)..."
cat << 'EOF' > /etc/nginx/sites-available/core || fail "gagal tulis config nginx"
server {
    listen 80;
    server_name core.zhari.yusuf.com;

    root /var/www/core;
    index index.php;

    # URL bersih: /profil -> /profil.php
    rewrite ^/profil/?$ /profil.php last;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:PHP_SOCK_PLACEHOLDER;
    }
}
EOF
sed -i "s#PHP_SOCK_PLACEHOLDER#$PHP_SOCK#" /etc/nginx/sites-available/core

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/core /etc/nginx/sites-enabled/core || fail "gagal aktifkan site"

nginx -t || fail "konfigurasi nginx error"

echo "[4] Restart + verifikasi..."
service "$PHP_SVC" restart || fail "restart $PHP_SVC gagal"
service nginx restart      || fail "restart nginx gagal"
sleep 2
service nginx status >/dev/null 2>&1 || fail "nginx tidak berjalan"
[ -S "$PHP_SOCK" ] || fail "socket PHP-FPM tidak ada: $PHP_SOCK"

R1=$(curl -s -H "Host: $WEB_HOST" http://127.0.0.1/)
echo "$R1" | grep -q "<h1>Beranda</h1>" || fail "halaman beranda tidak muncul"

CODE=$(curl -s -o /tmp/profil.out -w "%{http_code}" -H "Host: $WEB_HOST" http://127.0.0.1/profil)
[ "$CODE" = "200" ] || fail "/profil tidak 200 (kode: $CODE)"
grep -q "<h1>Profil</h1>" /tmp/profil.out || fail "halaman profil tidak muncul"

echo "Web core berhasil, PHP-FPM aktif dan /profil (URL bersih) berfungsi!"