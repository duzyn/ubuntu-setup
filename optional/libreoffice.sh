#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
: "${LOCALE:="zh_CN"}"

# https://launchpad.net/~libreoffice/+archive/ubuntu/ppa
if [[ -z "$(command -v libreoffice-writer)" ]]; then
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt-get update
    sudo apt-get install -y libreoffice

    if [[ "$LOCALE" == "zh_CN" ]]; then
        sudo apt-get install -y libreoffice-help-zh-cn libreoffice-l10n-zh-cn
    fi
fi
