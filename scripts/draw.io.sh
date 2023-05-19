#!/usr/bin/env bash

# https://github.com/jgraph/drawio-desktop/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps jgraph/drawio-desktop draw.io .deb
