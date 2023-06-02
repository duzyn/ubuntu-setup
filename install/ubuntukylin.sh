#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
: "${UBUNTU_CODENAME:="jammy"}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

# Some Windows apps on Ubuntu Kylin
# https://www.ubuntukylin.com/applications
if [[ ! -f /etc/apt/sources.list.d/ubuntukylin.list ]]; then
    echo "Adding Ubuntu Kylin apt repository..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56583E647FFA7DE7
    echo "deb http://archive.ubuntukylin.com/ubuntukylin $UBUNTU_CODENAME-partner main" | \
        sudo tee /etc/apt/sources.list.d/ubuntukylin.list
    sudo apt-get update
fi

echo "Installing Ubuntu Kylin apps..."
sudo apt-get install -y \
    weixin \
    wemeet \
    wps-office \
    xmind-vana

# PS6:
# sudo apt-get install -y ukylin-ps6
# Fix ADM  error when launch PS6
# if [[ -f "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" ]]; then
#     mv  "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" \
#         "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl.origin"
# fi

# WPS needs to install symbol fonts.
if [[ ! -d /usr/share/fonts/wps-fonts ]]; then
    echo "Installing WPS symbol fonts..."
    sudo mkdir -p /usr/share/fonts/wps-fonts
    sudo cp -r "$SCRIPT_DIR/../wps-fonts" /usr/share/fonts
    sudo chmod 644 /usr/share/fonts/wps-fonts/*
    sudo fc-cache -vfs
fi
