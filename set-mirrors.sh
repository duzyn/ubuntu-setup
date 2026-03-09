#!/bin/bash

set -e

sudo apt install -y wget

cd /tmp
wget -O linuxmirrors.sh https://linuxmirrors.cn/main.sh
chmod +x ./linuxmirrors.sh
sudo ./linuxmirrors.sh --en --source mirrors.tuna.tsinghua.edu.cn --protocol https --use-intranet-source false --upgrade-software false --ignore-backup-tips
cd -
