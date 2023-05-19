#!/usr/bin/env bash

# A simple script to setup up a new ubuntu installation.
# Author: David Peng
# Date: 2023-01-13

# Inspired by https://github.com/halvards/vagrant-xfce4-ubuntu and https://github.com/trxcllnt/ubuntu-setup/

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail

export DEBUG=False
if [[ ${DEBUG} != False ]]; then
  # Turn on traces, useful while debugging but commented out by default
  set -o xtrace
fi

function log() {
  echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
  local msg=$1
  local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
  log "$msg"
  exit "$code"
}

# Variables
export DEBIAN_FRONTEND=noninteractive

GITHUB_PROXY=https://ghproxy.com/
# GITHUB_PROXY=False

sudo apt-get update
sudo apt-get install -y p7zip-full

log "Downloading Ubuntu setup scripts…"
wget -O /tmp/ubuntu-setup.zip $([[ ${GITHUB_PROXY} != False ]] && echo "${GITHUB_PROXY}")https://github.com/duzyn/ubuntu-setup/archive/refs/heads/main.zip
log "Downloaded Ubuntu setup scripts."

log "Installing Ubuntu setup scripts…"
7z x -o/tmp /tmp/ubuntu-setup.zip
bash /tmp/ubuntu-setup-main/main.sh
log "Installed Ubuntu setup scripts."