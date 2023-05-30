#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

log "Insatlling or updating BCM4360 wifi driver..."
sudo apt-get install -y \
    dkms \
    bcmwl-kernel-source