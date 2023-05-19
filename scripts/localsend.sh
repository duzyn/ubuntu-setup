#!/usr/bin/env bash

./script/_upgrade_appimage_apps.sh || exit
upgrade_appimage_apps localsend/localsend localsend
