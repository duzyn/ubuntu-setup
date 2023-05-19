#!/usr/bin/env bash

# https://github.com/dbeaver/dbeaver/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps dbeaver/dbeaver dbeaver-ce amd64.deb

