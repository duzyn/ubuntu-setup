#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo "Insatlling BCM4360 wifi driver..."
sudo apt-get install -y \
    dkms \
    bcmwl-kernel-source