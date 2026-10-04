#!/bin/bash

apt update
apt install -y apache2-utils

echo "========================================"
echo "Benchmark www.zhari.yusuf.com"
echo "========================================"

ab -n 250 -c 10 http://www.zhari.yusuf.com/ \
| tee /root/benchmark_www.txt

echo ""
echo "========================================"
echo "Benchmark static.zhari.yusuf.com"
echo "========================================"

ab -n 250 -c 10 http://static.zhari.yusuf.com/ \
| tee /root/benchmark_static.txt

echo ""
echo "Hasil tersimpan pada:"
echo "/root/benchmark_www.txt"
echo "/root/benchmark_static.txt"