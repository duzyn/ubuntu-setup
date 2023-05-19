#!/usr/bin/env bash

# https://github.com/lyswhut/lx-music-desktop/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps lyswhut/lx-music-desktop lx-music-desktop x64.deb

