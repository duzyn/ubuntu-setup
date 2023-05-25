#!/usr/bin/env bash

# Ubuntu has discontinued preseed as of 20.04 according to this:
# https://discourse.ubuntu.com/t/server-installer-plans-for-20-04-lts/13631

# Arguments given to the download router.
: "${ISO_URL:="https://www.releases.ubuntu.com/20.04.6/ubuntu-20.04.6-desktop-amd64.iso"}"
: "${SOURCE_ISO:="$(basename "$ISO_URL")"}"

: "${DIST_DIR="dist"}"

# Hardcoded host information.
: "${USERNAME:="ubuntu"}"
: "${PASSWORD:="ubuntu"}"
: "${FULL_NAME:="ubuntu"}"
: "${HOST:="ubuntu"}"
: "${DOMAIN:="ubuntu.guest.virtualbox.org"}"
: "${LOCALE:="en_US"}"
: "${TIMEZONE:="America/Nome"}"

# Virtual machine
: "${VBOX_NAME:="${SOURCE_ISO%.*}"}"
: "${VBOX_OS_TYPE:=Ubuntu_64}"
: "${VBOX_CPU_NUMBER:=2}"
: "${VBOX_MEMORY:=2048}"
: "${VBOX_VRAM:=128}"
: "${VBOX_HDD_SIZE:=61440}"
: "${VBOX_HDD_FORMAT:=VDI}"
