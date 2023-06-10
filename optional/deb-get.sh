#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# deb-get
if [[ -z "$(command -v deb-get)" ]]; then
    wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get

fi

deb-get update
deb-get install bitwarden
