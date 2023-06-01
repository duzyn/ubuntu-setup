#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Inspired by https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
: "${DEBUG="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace
#  Configurations
: "${LOCALE:="zh_CN"}"
: "${APT_MIRROR:="mirrors.ustc.edu.cn"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"
: "${VTOYBOOT:="false"}"
: "${GITHUB_TOKEN:="your_github_token"}"

TMPDIR="$(mktemp -d)"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

export DEBIAN_FRONTEND=noninteractive

. "$SCRIPT_DIR/scripts/00-source-list.sh"
. "$SCRIPT_DIR/scripts/01-base.sh"
. "$SCRIPT_DIR/scripts/albert.sh"
. "$SCRIPT_DIR/scripts/drivers.sh"
. "$SCRIPT_DIR/scripts/extras.sh"
. "$SCRIPT_DIR/scripts/free-download-manager.sh"
# . "$SCRIPT_DIR/scripts/freecad.sh"
# . "$SCRIPT_DIR/scripts/libreoffice.sh"
# . "$SCRIPT_DIR/scripts/inkscape.sh"
. "$SCRIPT_DIR/scripts/fsearch.sh"
. "$SCRIPT_DIR/scripts/git.sh"
. "$SCRIPT_DIR/scripts/github-releases-apps.sh"
. "$SCRIPT_DIR/scripts/google-chrome.sh"
. "$SCRIPT_DIR/scripts/greenfish-icon-editor-pro.sh"
. "$SCRIPT_DIR/scripts/install-appimage-apps.sh"
. "$SCRIPT_DIR/scripts/just.sh"
. "$SCRIPT_DIR/scripts/locale.sh"
. "$SCRIPT_DIR/scripts/microsoft-edge.sh"
. "$SCRIPT_DIR/scripts/microsoft-to-do.sh" # nativefier web app
. "$SCRIPT_DIR/scripts/miktex.sh"
. "$SCRIPT_DIR/scripts/node.sh"
. "$SCRIPT_DIR/scripts/onedriver.sh"
. "$SCRIPT_DIR/scripts/theme.sh"
. "$SCRIPT_DIR/scripts/tor-browser.sh"
. "$SCRIPT_DIR/scripts/ubuntukylin.sh"
. "$SCRIPT_DIR/scripts/vim.sh"
. "$SCRIPT_DIR/scripts/visual-studio-code.sh"
# . "$SCRIPT_DIR/scripts/flatpak-apps.sh"
# . "$SCRIPT_DIR/scripts/wine.sh"

echo "Uninstalling unnecessary apps..."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Remove LibreOffice, use WPS Office instead.
sudo apt purge --autoremove libreoffice*

echo "Checking installed apps' update..."
sudo apt-get upgrade -y

. "$SCRIPT_DIR/scripts/vtoyboot.sh"
