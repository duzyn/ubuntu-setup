#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Inspired by https://github.com/trxcllnt/ubuntu-setup/

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
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

sudo apt-get update

### Base packages
sudo apt-get install -y \
    apt-transport-https \
    binutils \
    build-essential \
    bzip2 \
    ca-certificates \
    coreutils \
    curl \
    desktop-file-utils \
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
    sed \
    software-properties-common \
    tar \
    unzip \
    wget \
    zip

for FILE in "$SCRIPT_DIR"/install/*.sh; do
    # shellcheck source=/dev/null
    . "$FILE"
done

sudo apt-get clean -y
sudo apt-get autoremove -y
sudo apt-get upgrade -y
