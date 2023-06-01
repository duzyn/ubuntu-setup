#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo "Installing some base packages..."
sudo apt-get install -y \
    apt-transport-https \
    aria2 \
    binutils \
    build-essential \
    bzip2 \
    ca-certificates \
    coreutils \
    curl \
    desktop-file-utils \
    ffmpeg \
    file \
    g++ \
    gcc \
    gdebi \
    gpg \
    gzip \
    jq \
    libfuse2 \
    lsb-release \
    make \
    man-db \
    net-tools \
    ntp \
    p7zip-full \
    patch \
    procps \
    proxychains4 \
    sed \
    software-properties-common \
    tar \
    unzip \
    wget \
    zip