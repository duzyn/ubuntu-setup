#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Wine: https://wiki.winehq.org/Ubuntu_zhcn
if [[ -n "$(command -v winetricks)" ]]; then
    log "Wine is installed."
else
    log "Installing Wine..."
    sudo dpkg --add-architecture i386 
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources
    sudo apt-get update
    sudo apt install -y --install-recommends winehq-stable
fi

# Winetricks: https://github.com/Winetricks/winetricks
log "Installing or Updating Winetricks..."
wget -q -O "$TMPDIR/winetricks" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x "$TMPDIR/winetricks"
sudo cp "$TMPDIR/winetricks" /usr/local/bin

wget -q -O "$TMPDIR/winetricks.bash-completion" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion
sudo cp "$TMPDIR/winetricks.bash-completion" /usr/share/bash-completion/completions/winetricks