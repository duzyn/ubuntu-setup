#!/usr/bin/env bash

: "${NVM_NODEJS_ORG_MIRROR:="https://npmmirror.com/mirrors/node"}"
: "${NPM_REGISTRY_MIRROR:="https://registry.npmmirror.com"}"


export DEBIAN_FRONTEND=noninteractive

# Node, npm
echo "Installing nvm..."
wget --show-progress -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | \
    sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/raw.githubusercontent.com|g" \
        -e "s|https://github.com|https://ghproxy.com/github.com|g" | bash


export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "Installing latest version LTS nodejs..."
nvm install --lts

if grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
    echo "NVM_NODEJS_ORG_MIRROR is set."
else
    echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
    echo "NVM_NODEJS_ORG_MIRROR is set to $NVM_NODEJS_ORG_MIRROR."
fi

touch "$HOME/.npmrc"
if grep -q "registry=" "$HOME/.npmrc"; then
    echo "NPM_REGISTRY_MIRROR is set."
else
    echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
    echo "NPM_REGISTRY_MIRROR is set to $NPM_REGISTRY_MIRROR."
fi

sudo chown -R 1000:1000 "$HOME/.npm"

if [[ -n "$( command -v nativefier)" ]]; then
    echo "Nativefier is installed."
else
    echo "Installing Nativefier..."
    npm install -g nativefier
fi

echo "Upgrading packages..."
npm upgrade -g
