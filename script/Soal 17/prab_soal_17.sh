#!/bin/bash

ZONE_FILE="/etc/bind/db.zhari.yusuf.com"

cat >> $ZONE_FILE << 'EOF'

; TXT Records Soal 17
alpa    IN TXT "alpa"
beta    IN TXT "beta"
gamma   IN TXT "gamma"
delta   IN TXT "delta"
epsilon IN TXT "epsilon"
EOF

named-checkzone zhari.yusuf.com $ZONE_FILE

service bind9 restart