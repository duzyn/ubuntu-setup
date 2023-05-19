#!/usr/bin/env bash

log "Installing Vim GTK…"
sudo apt-get install -y vim vim-gtk
log "Installed Vim GTK."

# Usage: install_vim_plugin repo/name
install_vim_plugin() {
  local repo_name plugin_name
  repo_name=$1
  plugin_name="$(basename "${repo_name}")"

  mkdir -p "${HOME}/.vim/pack/plugins/start"
  if [[ ! -d "${HOME}/.vim/pack/plugins/start/${plugin_name}" ]]; then
    log "Installing Vim plugin ${plugin_name}…"
    git clone --depth 1 "$([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://github.com/${repo_name}" "${HOME}/.vim/pack/plugins/start/${plugin_name}"
    log "Installed Vim plugin ${plugin_name}."
  fi
}
install_vim_plugin yianwillis/vimcdoc
install_vim_plugin sheerun/vim-polyglot

if [[ -f .vimrc ]]; then
  cp .vimrc "${HOME}/"
  log "Copied .vimrc file."
else
  log "Skipping .vimrc file."
fi