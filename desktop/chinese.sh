#!/bin/bash
set -e

# Install Chinese language packs
sudo apt install -y language-pack-zh-hans language-pack-gnome-zh-hans

# Install Fcitx5 and Pinyin
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8

# Set Fcitx5 as default input method
im-config -n fcitx5

# Configure environment variables
for var in "GTK_IM_MODULE=fcitx" "QT_IM_MODULE=fcitx" "XMODIFIERS=@im=fcitx"; do
    if ! grep -q "^${var}$" /etc/environment; then
        echo "$var" | sudo tee -a /etc/environment
    fi
done
