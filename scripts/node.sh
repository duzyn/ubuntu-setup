#!/usr/bin/env bash

NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
NPM_REGISTRY_MIRROR=https://registry.npmmirror.com

# https://github.com/nvm-sh/nvm
log "Installing nvm…"
curl https://cdn.jsdelivr.net/gh/nvm-sh/nvm@0.39.3/install.sh | bash
log "Installed nvm."

export NVM_DIR="${HOME}/.nvm"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
# shellcheck source=/dev/null
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"

log "Installing latest version LTS nodejs…"
nvm install --lts
log "Installed latest version LTS nodejs."

if [[ ${NVM_NODEJS_ORG_MIRROR} != False ]]; then
  if grep -q "NVM_NODEJS_ORG_MIRROR" "${HOME}/.bashrc"; then
    echo "export NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" >>"${HOME}/.bashrc"
    log "Using NVM_NODEJS_ORG_MIRROR: ${NVM_NODEJS_ORG_MIRROR}"
  else
    log "NVM_NODEJS_ORG_MIRROR already exists."
  fi
else
  log "Using official nodejs mirror."
fi

touch "${HOME}/.npmrc"
if [[ ${NPM_REGISTRY_MIRROR} ]]; then
  if grep -q "registry" "${HOME}/.npmrc"; then
    log "registry=${NPM_REGISTRY_MIRROR}" >>"${HOME}/.npmrc"
    log "Using NPM_REGISTRY_MIRROR: ${NPM_REGISTRY_MIRROR}"
  else
    log "NPM_REGISTRY_MIRROR already exists."
  fi
else
  log "Using official npm mirror."
fi

log "Updating npm…"
npm update -g
log "Updated npm."