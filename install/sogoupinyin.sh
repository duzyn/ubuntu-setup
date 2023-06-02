#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

SOGOUPINYIN_INSTALLED_VERSION="not_installed"
SOGOUPINYIN_LATEST_VERSION="$(wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb" | cut -f2 -d "_")"
if dpkg -s sogoupinyin &>/dev/null; then
    SOGOUPINYIN_INSTALLED_VERSION="$(dpkg -s sogoupinyin | grep Version: | cut -f2 -d " ")"
    echo "Sogou Pinyin $SOGOUPINYIN_INSTALLED_VERSION is installed."
fi

if [[ "$SOGOUPINYIN_LATEST_VERSION" == *"$SOGOUPINYIN_INSTALLED_VERSION"* || "$SOGOUPINYIN_INSTALLED_VERSION" == *"$SOGOUPINYIN_LATEST_VERSION"* ]]; then
    echo "Sogou Pinyin $SOGOUPINYIN_INSTALLED_VERSION is lastest."
else
    echo "Installing Sogou Pinyin $SOGOUPINYIN_LATEST_VERSION..."
    wget -O "$TMPDIR/sogoupinyin.deb" "$(wget -qO- https://shurufa.sogou.com/linux | grep -Po "https://ime-sec.*?amd64.deb")"
    sudo gdebi -n "$TMPDIR/sogoupinyin.deb"
fi