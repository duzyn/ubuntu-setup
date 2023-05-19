#!/usr/bin/env bash

# https://miktex.org/download#ubuntu and 
# https://mirrors.bfsu.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if dpkg -s "miktex" &> /dev/null; then
  echo "MiKTeX is installed."
else
  log "Installing MiKTeX…"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
  echo "deb http://miktex.org/download/ubuntu focal universe" | sudo tee /etc/apt/sources.list.d/miktex.list
fi
sudo apt-get update
sudo apt-get install -y miktex
log "Installed MiKTeX."

# Finish the setup.
# Before you can use MiKTeX, you have to finish the setup.
# You can use MiKTeX Console or, if you prefer the command line, `miktexsetup`.

# finish with a private (for you only) TeX installation. Executables like
# lualatex will be installed in ~/bin.
miktexsetup finish

# You also may want to enable automatic package installation:
initexmf --set-config-value \[MPM\]AutoInstall=1

# If you don't use mirror, you can comment this.
initexmf --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/

