#!/usr/bin/env bash

# Install Sogou pinyin, should uninstall fcitx-ui-qimpanel first.
log "Installing fcitx config GUI…"
sudo apt-get install -y fcitx fcitx-config-gtk
log "Installed fcitx config GUI."

log "Uninstalling some unnecessary fcitx IME. fcitx-ui-qimpanel isn't compatible with Sogou Pinyin package, so uninstall it too."
sudo apt-get remove -y \
  fcitx-chewing \
  fcitx-pinyin \
  fcitx-sunpinyin \
  fcitx-table-cangjie \
  fcitx-table-wubi \
  fcitx-ui-qimpanel
sudo apt-get autoremove -y
log "Uninstalled these packages."

if dpkg -s "sogoupinyin" &> /dev/null; then
  log "Sogou Pinyin is installed."
else
  log "Installing Sogou Pinyin dependencies…"
  sudo apt-get install -y \
    libgsettings-qt1 \
    libqt5qml5 \
    libqt5quick5 \
    libqt5quickwidgets5 \
    qml-module-qtquick2
  log "Installed Sogou Pinyin dependencies."

  log "Downloading Sogou Pinyin…"
  # wget -O /tmp/sogou-pinyin.deb https://archive.ubuntukylin.com/software/pool/partner/sogoupinyin_2.4.0.3469_amd64.deb
  wget -O /tmp/sogou-pinyin.deb https://ime-sec.gtimg.com/202305181446/a3a810d5bc1e188c23d3601fa8a71b0b/pc/dl/gzindex/1680521603/sogoupinyin_4.2.1.145_amd64.deb
  log "Downloaded Sogou Pinyin."

  log "Installing Sogou Pinyin…"
  sudo gdebi -n /tmp/sogou-pinyin.deb
  log "Installed Sogou Pinyin."
fi
