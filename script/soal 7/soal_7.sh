#!/bin/bash

# 1. Otomatis ubah angka serial SOA (misal dari 2 jadi 3)
sed -i 's/\b2\b/3/' /etc/bind/db.zhari.yusuf.com

# 2. Tambahkan record Vault, Core, dan CNAME lewat heredoc
cat << 'EOF' >> /etc/bind/db.zhari.yusuf.com

; --- Record untuk Soal No. 7 (Vault, Core, dan CNAME) ---
vault   IN  A   10.75.1.12
vault   IN  A   10.75.1.13
core    IN  A   10.75.1.14
core    IN  A   10.75.1.15

www     IN  CNAME   penny.zhari.yusuf.com.
static  IN  CNAME   abbey.zhari.yusuf.com.
EOF

# 3. Restart layanan BIND9 agar update diterapkan & tersinkronisasi ke tedd
service bind9 restart