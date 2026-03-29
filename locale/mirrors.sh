#!/bin/bash
set -e pipefail

SOURCES_FILE="/etc/apt/sources.list.d/official-package-repositories.list"

sudo tee "$SOURCES_FILE" > /dev/null << 'EOF'
deb https://mirrors.tuna.tsinghua.edu.cn/linuxmint zena main upstream import backport
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu noble-security main restricted universe multiverse
EOF

sudo apt-get update -y
