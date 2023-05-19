#!/usr/bin/env bash

# https://github.com/Zettlr/Zettlr/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps Zettlr/Zettlr zettlr amd64.deb
