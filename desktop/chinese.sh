#!/bin/bash

# Install Chinese language packs
sudo apt update
sudo apt install -y language-pack-zh-hans language-pack-gnome-zh-hans

# Install Fcitx5 and Pinyin
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8

# Set Fcitx5 as default input method
im-config -n fcitx5

# Configure environment variables
if ! grep -q "GTK_IM_MODULE=fcitx" /etc/environment; then
    echo "GTK_IM_MODULE=fcitx" | sudo tee -a /etc/environment
    echo "QT_IM_MODULE=fcitx" | sudo tee -a /etc/environment
    echo "XMODIFIERS=@im=fcitx" | sudo tee -a /etc/environment
fi
