#!/usr/bin/env bash

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
set -o xtrace

# 使用 Joplin 官方提供的安装、升级脚本，但是改良两点：
# 1. 使用 GitHub Token 来访问 api 地址，降低访问失败的风险
# 2. 将下载链接替换为代理地址，使得在中国可以访问

wget -qO- https://ghproxy.com/https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | \
    sed -E 's|https://objects\.joplinusercontent\.com/(v\$\{RELEASE_VERSION\}/Joplin-\$\{RELEASE_VERSION\}\.AppImage)\?source=LinuxInstallScript\&type=\$DOWNLOAD_TYPE|https://ghproxy.com/https://github.com/laurent22/joplin/releases/download/\1|g' | \
    sed -E "s|(\"?https://api\.github\.com)|--header=\"Authorization: Bearer $GITHUB_TOKEN\" \1|g" | bash
