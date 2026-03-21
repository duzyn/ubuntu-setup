#!/bin/bash
set -e

# https://github.com/vinceliuice/grub2-themes
cd /tmp
git clone --depth=1 "${GH_PROXY}https://github.com/vinceliuice/grub2-themes.git"
sudo /bin/bash grub2-themes/install.sh --boot --theme tela --icon color --screen 1080p
cd -