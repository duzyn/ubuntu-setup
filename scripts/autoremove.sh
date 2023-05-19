#!/usr/bin/env bash

log "Uninstalling some unnecessary apps…"
# sudo apt-get purge -y \
#   gnome-mines \
#   gnome-sudoku \
#   parole \
#   pidgin* \
#   sgt-launcher \
#   sgt-puzzles \
sudo apt-get clean -y
sudo apt-get autoremove -y
log "Uninstalled these unnecessary apps."