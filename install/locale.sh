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
: "${LOCALE:="zh_CN"}"

# Locale
if [[ "$LOCALE" == "zh_CN" ]]; then
    sudo apt-get install -y \
        language-pack-gnome-zh-hans \
        language-pack-zh-hans \
        fonts-arphic-ukai \
        fonts-arphic-uming \
        fonts-noto-cjk \
        fonts-noto-cjk-extra
fi

sudo update-locale LANG="$LOCALE.UTF-8" LANGUAGE="$LOCALE"

# https://gnu-linux.readthedocs.io/zh/latest/Chapter02/46_xdg.user.dirs.html
# cat ~/.config/user-dirs.dirs
mkdir -p \
    "$HOME/Desktop" \
    "$HOME/Documents" \
    "$HOME/Downloads" \
    "$HOME/Music" \
    "$HOME/Pictures" \
    "$HOME/Public" \
    "$HOME/Templates" \
    "$HOME/Videos"
xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
xdg-user-dirs-update --set DOWNLOAD "$HOME/Downloads"
xdg-user-dirs-update --set MUSIC "$HOME/Music"
xdg-user-dirs-update --set PICTURES "$HOME/Pictures"
xdg-user-dirs-update --set PUBLICSHARE "$HOME/Public"
xdg-user-dirs-update --set TEMPLATES "$HOME/Templates"
xdg-user-dirs-update --set VIDEOS "$HOME/Videos"

