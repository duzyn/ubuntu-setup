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

# MiKTeX
# https://miktex.org/download#ubuntu and
# https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/doc/miktex.pdf
if [[ -z "$(command -v miktex)" ]]; then
    wget -qO- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD6BC243565B2087BC3F897C9277A7293F59E4889" | \
        gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/miktex.gpg >/dev/null

    echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/setup/deb $(lsb_release -cs) universe" | \
        sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install -y miktex

    # https://docs.miktex.org/manual/miktexsetup.html
    # Finish with a shared (system-wide) TeX installation. Executables like lualatex will be installed in /usr/local/bin.
    sudo miktexsetup --shared=yes finish

    # You also may want to enable automatic package installation:
    sudo initexmf --admin --set-config-value \[MPM\]AutoInstall=1

    # If you don't use mirror, you can comment this.
    sudo initexmf --admin --set-config-value \[MPM\]RemoteRepository=https://mirrors.ustc.edu.cn/CTAN/systems/win32/miktex/tm/packages/
fi
