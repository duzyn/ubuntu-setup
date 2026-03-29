#!/bin/bash
set -euo pipefail

# Install Chinese language packs
sudo apt install -y \
    language-pack-zh-hans \
    language-pack-gnome-zh-hans \
    language-pack-kde-zh-hans

command -v firefox &>/dev/null && \
    sudo apt install -y firefox-locale-zh-hans

command -v thunderbird &>/dev/null && \
    sudo apt install -y thunderbird-locale-zh-hans

command -v libreoffice &>/dev/null && \
    sudo apt install -y libreoffice-l10n-zh-cn

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8