#!/usr/bin/env bash

function get_package_version() {
    if dpkg -s "$1" &>/dev/null; then
        dpkg -s "$1" | grep Version: | cut -f2 -d " "
    else
        echo "not_installed"
    fi
}