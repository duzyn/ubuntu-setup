#!/usr/bin/env bash

log "Installing some base packages…"
  sudo apt-get update
  apt-transport-https \
  bzip2 \
  ca-certificates \
  coreutils \
  curl \
  gdebi \
  git \
  gzip \
  gpg \
  jq \
  libfuse2 \
  lsb-release \
  man-db \
  p7zip-full \
  patch \
  proxychains4 \
  sed \
  software-properties-common \
  tar \
  unzip \
  wget \
  zip
log "Installed some base packages."
