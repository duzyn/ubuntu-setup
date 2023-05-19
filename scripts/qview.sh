#!/usr/bin/env bash

# https://github.com/jurplel/qView/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps jurplel/qView qview amd64.deb
