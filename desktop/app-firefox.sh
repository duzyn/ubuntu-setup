#!/bin/bash

set -e

if command -v firefox &>/dev/null; then
  xdg-settings set default-web-browser firefox.desktop
fi

