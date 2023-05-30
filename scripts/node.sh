#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Node, npm
log "Installing nvm..."
if eval "curl -sk https://raw.githubusercontent.com" >> /dev/null 2>&1; then
    log "Connected to GitHub!"
    wget -qO- "https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | bash
elif eval "curl -sk https://ghproxy.com" >> /dev/null 2>&1; then
    log "Connected to GitHub Proxy!"
    wget -qO- "https://ghproxy.com/raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh" | \
        sed -e "s|https://raw.githubusercontent.com|https://ghproxy.com/raw.githubusercontent.com|g" \
            -e "s|https://github.com|https://ghproxy.com/github.com|g" | bash
else
    die "Failed! No internet connection available."
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

log "Installing latest version LTS nodejs..."
nvm install --lts

if grep -q "NVM_NODEJS_ORG_MIRROR=" "$HOME/.bashrc"; then
    log "NVM_NODEJS_ORG_MIRROR is set."
else
    echo "export NVM_NODEJS_ORG_MIRROR=$NVM_NODEJS_ORG_MIRROR" >>"$HOME/.bashrc"
    log "NVM_NODEJS_ORG_MIRROR is set to $NVM_NODEJS_ORG_MIRROR."
fi

touch "$HOME/.npmrc"
if grep -q "registry=" "$HOME/.npmrc"; then
    log "NPM_REGISTRY_MIRROR is set."
else
    echo "registry=$NPM_REGISTRY_MIRROR" >>"$HOME/.npmrc"
    log "NPM_REGISTRY_MIRROR is set to $NPM_REGISTRY_MIRROR."
fi

sudo chown -R 1000:1000 "$HOME/.npm"

if [[ -n "$( command -v nativefier)" ]]; then
    log "Nativefier is installed."
else
    log "Installing Nativefier..."
    npm install -g nativefier
fi

log "Upgrading packages..."
npm upgrade -g
