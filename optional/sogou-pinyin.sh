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
TEMP_DIR=$(mktemp -d)

# Sogou Pinyin is not compatible with fcitx5.
if dpkg -s fcitx5 &>/dev/null; then
    sudo apt purge --auto-remove -y fcitx5*
fi

LATEST_VERSION=$(wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | cut -f2 -d "_")

if dpkg -s sogoupinyin &>/dev/null; then
    CURRENT_VERSION=$(dpkg -s sogoupinyin | grep ^Version: | cut -f2 -d " ")
else
    CURRENT_VERSION=noversion
fi

if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | \
        xargs wget -O "$TEMP_DIR/sogoupinyin.deb"
    sudo apt-get remove -y fcitx-ui-qimpanel
    if command -v gdebi &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y gdebi
    fi
    sudo apt-get install -y libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2 libgsettings-qt1
    sudo gdebi -n "$TEMP_DIR/sogoupinyin.deb"
    # sudo apt-mark hold fcitx-ui-qimpanel
fi

rm -rf "$TEMP_DIR"
