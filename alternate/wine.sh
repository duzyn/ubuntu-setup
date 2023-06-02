#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Wine: https://wiki.winehq.org/Ubuntu_zhcn
if [[ -n "$(command -v winetricks)" ]]; then
    echo "Wine is installed."
else
    echo "Installing Wine..."
    sudo dpkg --add-architecture i386 
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget --show-progress -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        
    sudo wget --show-progress -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources
    sudo apt-get update
    sudo apt install -y --install-recommends winehq-stable
fi

# Winetricks: https://github.com/Winetricks/winetricks
echo "Installing or Updating Winetricks..."
wget --show-progress -q -O "$TMPDIR/winetricks" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x "$TMPDIR/winetricks"
sudo cp "$TMPDIR/winetricks" /usr/local/bin

wget --show-progress -q -O "$TMPDIR/winetricks.bash-completion" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion
sudo cp "$TMPDIR/winetricks.bash-completion" /usr/share/bash-completion/completions/winetricks