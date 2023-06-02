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

TMPDIR="$(mktemp -d)"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

export DEBIAN_FRONTEND=noninteractive

for FILE in "$SCRIPT_DIR"/install/*.sh; do
    # shellcheck source=/dev/null
    . "$FILE"
done

echo "Uninstalling unnecessary apps..."
sudo apt-get clean -y
sudo apt-get autoremove -y

# Remove LibreOffice, use WPS Office instead.
sudo apt purge --autoremove libreoffice*

echo "Checking installed apps' update..."
sudo apt-get upgrade -y

. "$SCRIPT_DIR/install/vtoyboot.sh"
