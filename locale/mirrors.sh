#!/bin/bash
set -e pipefail

SOURCES_FILE="/etc/apt/sources.list.d/official-package-repositories.list"

sudo tee "$SOURCES_FILE" > /dev/null << 'EOF'
deb https://mirrors.aliyun.com/linuxmint-packages zena main upstream import backport
deb https://mirrors.aliyun.com/ubuntu noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu noble-backports main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu noble-security main restricted universe multiverse
EOF

sudo apt-get update -y
