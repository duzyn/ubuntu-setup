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

sudo apt-get install -y \
    android-sdk-platform-tools \
    ffmpeg \
    filezilla \
    ghostscript \
    gimp \
    libvips-tools \
    mupdf \
    mupdf-tools \
    neofetch \
    network-manager-openvpn-gnome \
    openvpn \
    pdfarranger \
    proxychains4 \
    scrcpy \
    scribus \
    vlc
