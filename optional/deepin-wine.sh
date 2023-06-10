#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# https://github.com/zq1997/deepin-wine
sudo dpkg --add-architecture i386
echo "deb [trusted=yes] https://deepin-wine.i-m.dev /" | sudo tee /etc/apt/sources.list.d/deepin-wine.i-m.dev.list

cat <<EOF | sudo tee /etc/profile.d/deepin-wine.i-m.dev.sh
XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
for deepin_dir in /opt/apps/*/entries; do
   if [ -d "$deepin_dir/applications" ]; then
      XDG_DATA_DIRS="$XDG_DATA_DIRS:$deepin_dir"
   fi
done
export XDG_DATA_DIRS
EOF

sudo apt-get update
sudo apt-get install -y com.qq.weixin.deepin com.qq.weixin.work.deepin