#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if [[ -n "$(command -v miktex)" ]]; then
    echo "MiKTeX is installed."
else
    echo "Adding MiKTeX apt repository..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/setup/deb $(lsb_release -cs) universe" | \
        sudo tee /etc/apt/sources.list.d/miktex.list

    echo "Installing MiKTeX..."
    sudo apt-get update
    sudo apt-get install -y miktex

    # Finish the setup.
    # Before you can use MiKTeX, you have to finish the setup.
    # You can use MiKTeX Console or, if you prefer the command line, `miktexsetup`.
    # https://docs.miktex.org/manual/miktexsetup.html
    # Finish with a shared (system-wide) TeX installation. Executables like lualatex will be installed in /usr/local/bin.
    sudo miktexsetup --shared=yes finish

    # You also may want to enable automatic package installation:
    sudo initexmf --admin --set-config-value \[MPM\]AutoInstall=1

    # If you don't use mirror, you can comment this.
    sudo initexmf --admin --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/
fi