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

# https://github.com/TheAssassin/AppImageLauncher
if [[ -z "$(command -v appimagelauncher)" ]]; then
    sudo add-apt-repository -y ppa:appimagelauncher-team/stable
    sudo apt-get update
    sudo apt-get install -y appimagelauncher
fi
