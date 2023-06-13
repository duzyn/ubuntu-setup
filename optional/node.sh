#!/usr/bin/env bash

: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"

export DEBIAN_FRONTEND=noninteractive

# Node
wget -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | \
    sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/https://raw.githubusercontent.com|g" \
    -e "s|https://github.com|https://ghproxy.com/https://github.com|g" | bash

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts

if ! grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
    echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
fi

touch "$HOME/.npmrc"
if ! grep -q "registry=" "$HOME/.npmrc"; then
    echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
fi

sudo chown -R 1000:1000 "$HOME/.npm"

# if [[ -z "$( command -v nativefier)" ]]; then
#     npm install -g nativefier
# fi

npm upgrade -g

