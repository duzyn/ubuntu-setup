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
: "${LOCALE:="zh_CN"}"

# https://launchpad.net/~libreoffice/+archive/ubuntu/ppa
if ! dpkg -s libreoffice &>/dev/null; then
    sudo add-apt-repository -y ppa:libreoffice/ppa
    sudo apt-get update
    sudo apt-get install -y libreoffice

    if [[ "$LOCALE" == "zh_CN" ]]; then
        sudo apt-get install -y libreoffice-help-zh-cn libreoffice-l10n-zh-cn
    fi
fi
