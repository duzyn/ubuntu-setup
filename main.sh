#!/usr/bin/env bash

./script/apt.sh || exit
./script/base.sh || exit
./script/locale.sh || exit
./script/sogou-pinyin.sh || exit
./script/chrome.sh || exit
./script/edge.sh || exit
./script/vscode.sh || exit
./script/node.sh || exit
./script/free-download-manager.sh || exit

# App on GitHub Releases
./script/pandoc.sh || exit
./script/draw.io.sh || exit
./script/dbeaver.sh || exit
./script/qview.sh || exit
./script/zettlr.sh || exit
./script/lx-music.sh || exit

./script/extras.sh || exit
./script/wps.sh || exit
# ./script/vim.sh || exit

# AppImage
./script/joplin.sh || exit
./script/localsend.sh || exit

./script/tor-browser.sh || exit
./script/gfie.sh || exit
./script/miktex.sh || exit
./script/wechat.sh || exit
./script/wechat-work.sh || exit
./script/tencent-meeting.sh || exit
./script/xunlei.sh || exit
./script/photoshop.sh || exit

# Post Install
# ./script/autoremove.sh || exit
./script/vtoyboot.sh || exit


# TODO freemind, fsearch, axure



