#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Greenfish Icon Editor Pro
# TODO update
if [[ -n "$(command -v gfie)" ]]; then
    log "Greenfish Icon Editor Pro is installed."
else
    log "Installing Greenfish Icon Editor Pro..."
    wget -O "$TMPDIR/gfie.deb" http://greenfishsoftware.org/dl/gfie/gfie-4.2.deb
    sudo gdebi -n "$TMPDIR/gfie.deb"
fi
