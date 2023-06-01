#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
TMPDIR="$(mktemp -d)"

# Greenfish Icon Editor Pro
# TODO update
if [[ -n "$(command -v gfie)" ]]; then
    echo "Greenfish Icon Editor Pro is installed."
else
    echo "Installing Greenfish Icon Editor Pro..."
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
fi
