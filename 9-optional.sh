#!/bin/bash
set -euo pipefail

PACKAGES=(
  calibre
  digikam
  freecad
  gimp
  handbrake
  libreoffice
  pdfarranger
  vlc
)

sudo apt-get install -y "${PACKAGES[@]}"
