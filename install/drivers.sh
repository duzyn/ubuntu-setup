#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo "Insatlling BCM4360 wifi driver..."
sudo apt-get install -y \
    dkms \
    bcmwl-kernel-source

echo "Insatlling Nvidia GPU driver..."
sudo apt-get install -y nvidia-driver-530
