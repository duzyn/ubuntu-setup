#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Greenfish Icon Editor Pro
# TODO update
if dpkg -s gfie &>/dev/null; then
    echo "Greenfish Icon Editor Pro is installed."
else
    echo "Installing Greenfish Icon Editor Pro..."
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
fi
