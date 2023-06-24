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

export DEBIAN_FRONTEND=noninteractive
# SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

if [[ -z "$(command -v proxychains4)" ]]; then
    sudo apt-get install -y proxychains4
fi

# 使用 Tor 做代理
if grep -P "^socks5\s*127\.0\.0\.1\s*9150" /etc/proxychains4.conf; then
    sudo sed -i -e "s|^socks5.*$|socks5  127.0.0.1 9150|g" /etc/proxychains4.conf
fi

# 使用 gfwlist PAC 做系统代理
# wget -qO- --header="Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/iBug/pac/releases/latest | \
#     grep -Po "https://.+pac-gfwlist-17mon\.txt\.gz" | head -n 1 | \
#     sed -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | \
#     xargs wget -O "$SCRIPT_DIR/pac-gfwlist-17mon.txt.gz"
# gzip -d -f "$SCRIPT_DIR/pac-gfwlist-17mon.txt.gz"
# rm -f "$SCRIPT_DIR/pac-gfwlist-17mon.txt.gz"

# if [[ -f "$SCRIPT_DIR/pac-gfwlist-17mon.txt" ]]; then
#     sed -i -e "s|^var\s*proxy.*$|var proxy = 'SOCKS5 127.0.0.1:9150; DIRECT;';|g" "$SCRIPT_DIR/pac-gfwlist-17mon.txt"
# fi
