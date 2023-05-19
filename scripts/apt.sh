#!/usr/bin/env bash

APT_MIRROR=mirrors.ustc.edu.cn/ubuntu
# APT_MIRROR=False

if [[ "${APT_MIRROR}" != False ]]; then
  log "Using APT proxy: ${APT_MIRROR}."
  sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
  sudo sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
  sudo sed -i 's/http:/https:/g' /etc/apt/sources.list
  sudo apt-get update
else
  log "Using official Ubuntu apt mirror."
fi