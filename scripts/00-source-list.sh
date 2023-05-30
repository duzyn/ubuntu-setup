#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Can't connect to freedownloadmanager repo, so remove it.
if [[ -f /etc/apt/sources.list.d/freedownloadmanager.list ]]; then
    log "Removing Free Download Manager mirror list..."
    sudo rm /etc/apt/sources.list.d/freedownloadmanager.list
else
    log "Free Download Manager mirror list doesn't exist."
fi

# Using APT mirror.
if [[ -f /etc/apt/sources.list ]]; then
    log "APT mirror is set to $APT_MIRROR."
    sudo sed -i -e "s|//.*archive.ubuntu.com|//$APT_MIRROR|g" -e "s|security.ubuntu.com|$APT_MIRROR|g" \
        -e "s|http:|https:|g" /etc/apt/sources.list
else
    die "There's no sources.list."
fi

log "Updating APT..."
sudo apt-get update
