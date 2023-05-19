#!/usr/bin/env bash

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

# https://github.com/jgm/pandoc/releases
./script/_upgrade_github_hosted_apps.sh || exit
upgrade_github_hosted_apps jgm/pandoc pandoc amd64.deb

if [[ -d "${HOME}/.local/share/pandoc" ]]; then
  cd "${HOME}/.local/share/pandoc" || exit
  git pull
else
  git clone --depth 1 "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://github.com/duzyn/pandoc-templates" "${HOME}/.local/share/pandoc"
fi