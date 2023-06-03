#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
: "${UBUNTU_CODENAME:="focal"}"

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


