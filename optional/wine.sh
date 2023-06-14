#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

export DEBIAN_FRONTEND=noninteractive
TEMP_DIR="$(mktemp -d)"

# Wine: https://wiki.winehq.org/Ubuntu_zhcn
if [[ -z "$(command -v winetricks)" ]]; then
    sudo dpkg --add-architecture i386 
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
        
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources
    sudo apt-get update
    sudo apt install -y --install-recommends winehq-stable
fi

# Winetricks: https://github.com/Winetricks/winetricks
wget -q -O "$TEMP_DIR/winetricks" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
chmod +x "$TEMP_DIR/winetricks"
sudo cp "$TEMP_DIR/winetricks" /usr/local/bin

wget -q -O "$TEMP_DIR/winetricks.bash-completion" https://ghproxy.com/https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks.bash-completion
sudo cp "$TEMP_DIR/winetricks.bash-completion" /usr/share/bash-completion/completions/winetricks

rm -rf "$TEMP_DIR"
