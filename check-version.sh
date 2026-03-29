#!/bin/bash
set -e pipefail

# Check if running on Linux Mint 22 (Wilma) or later
if ! command -v lsb_release &>/dev/null; then
    echo "Error: lsb_release not found. Cannot detect OS version."
    exit 1
fi

DISTRIBUTOR=$(lsb_release -is)
RELEASE=$(lsb_release -rs)
CODENAME=$(lsb_release -cs)

# Parse version number
MAJOR_VERSION=$(echo "$RELEASE" | cut -d. -f1)

if [ "$DISTRIBUTOR" != "Linuxmint" ]; then
    echo "Error: This script only supports Linux Mint."
    echo "Detected: $DISTRIBUTOR $RELEASE"
    exit 1
fi

if [ "$MAJOR_VERSION" != 22 ]; then
    echo "Error: This script requires Linux Mint 22."
    echo "Detected: Linux Mint $RELEASE ($CODENAME)"
    exit 1
fi

echo "Detected: Linux Mint $RELEASE ($CODENAME) - OK"