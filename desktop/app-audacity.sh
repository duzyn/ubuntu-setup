#!/bin/bash

set -e

if ! command -v audacity &>/dev/null; then
  sudo apt install -y audacity
fi


