#!/bin/bash

set -e

if command -v audacity &>/dev/null; then
  exit 0
fi


sudo apt install -y audacity
