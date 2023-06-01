#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Some Windows apps on Ubuntu Kylin
# https://www.ubuntukylin.com/applications
if [[ -f /etc/apt/sources.list.d/ubuntukylin.list ]]; then
    echo "Ubuntu Kylin mirror list is added."
else
    echo "Adding Ubuntu Kylin apt repository..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 56583E647FFA7DE7
    echo "deb http://archive.ubuntukylin.com/ubuntukylin $(lsb_release -cs)-partner main" | \
        sudo tee /etc/apt/sources.list.d/ubuntukylin.list
    sudo apt-get update
fi

echo "Installing Ubuntu Kylin apps..."
sudo apt-get install -y \
    com.xunlei.download \
    sogoupinyin \
    ukylin-ps6 \
    ukylin-wine \
    ukylin-wxwork \
    weixin \
    wemeet \
    wps-office \
    xmind-vana

# Fix ADM  error when launch PS6
if [[ -f "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" ]]; then
    mv  "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl" \
        "$HOME/.ukylin-wine/photoshop-cs6/drive_c/Program Files/Adobe/Photoshop CS6/Required/Plug-ins/ADM/ADMPlugin.apl.backup"
fi

# WPS needs to install symbol fonts.
if dpkg -s wps-fonts &>/dev/null; then
    echo "WPS fonts is installed."
else
    echo "Adding WPS fonts apt repository..."
    sudo add-apt-repository ppa:atareao/atareao 

    echo "Installing WPS symbol fonts..."
    sudo apt-get update
    sudo apt-get install -y wps-fonts
fi
