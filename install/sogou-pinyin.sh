#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR=$(mktemp -d)

### Sogou Pinyin
# Sogou Pinyin is not compatible with fcitx5.
LATEST_VERSION=$(wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | cut -f2 -d "_")
CURRENT_VERSION=noversion
CURRENT_VERSION=$(dpkg -s sogoupinyin &>/dev/null && dpkg -s sogoupinyin | grep Version: | cut -f2 -d " ")

if [[ "${LATEST_VERSION}" != "${CURRENT_VERSION}" ]]; then
    wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | \
        xargs wget -O "$TEMP_DIR/sogoupinyin.deb"
    sudo apt-get remove -y fcitx-ui-qimpanel
    sudo apt-get update
    sudo apt-get install -y gdebi
    sudo apt-get install -y libqt5qml5 libqt5quick5 libqt5quickwidgets5 qml-module-qtquick2 libgsettings-qt1
    sudo gdebi -n "$TEMP_DIR/sogoupinyin.deb"
    # sudo apt-mark hold fcitx-ui-qimpanel
fi

rm -rf "$TEMP_DIR"
