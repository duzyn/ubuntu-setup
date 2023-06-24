#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

export DEBIAN_FRONTEND=noninteractive

# https://github.com/zq1997/deepin-wine
# 谨慎使用，会夹带 Deepin 的诸多包，可能会弄乱系统的依赖关系。
sudo dpkg --add-architecture i386
echo "deb [trusted=yes] https://deepin-wine.i-m.dev /" | sudo tee /etc/apt/sources.list.d/deepin-wine.i-m.dev.list

if [[ ! -e /etc/profile.d/deepin-wine.i-m.dev.sh ]]; then
sudo tee "/etc/profile.d/deepin-wine.i-m.dev.sh" >/dev/null << "EOF"
XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
for deepin_dir in /opt/apps/*/entries; do
    if [ -d "$deepin_dir/applications" ]; then
        XDG_DATA_DIRS="$XDG_DATA_DIRS:$deepin_dir"
    fi
done
export XDG_DATA_DIRS
EOF
fi

sudo apt-get update
sudo apt-get install -y com.qq.weixin.deepin com.qq.weixin.work.deepin