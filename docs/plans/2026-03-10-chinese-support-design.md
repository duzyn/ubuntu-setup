# Design: Chinese Support for Ubuntu

## Overview
Implement a script to provide comprehensive Chinese language support on Ubuntu, focusing on Simplified Chinese (zh_CN), Fcitx5 input method with Pinyin, and system-wide locale configuration.

## Proposed Changes

### 1. Script Location
- **Path:** `desktop/chinese.sh`
- **Integration:** Automatically sourced by `desktop.sh`.

### 2. Package Installation
The script will install:
- `language-pack-zh-hans`
- `language-pack-gnome-zh-hans`
- `fcitx5`
- `fcitx5-chinese-addons`
- `fcitx5-frontend-gtk2`
- `fcitx5-frontend-gtk3`
- `fcitx5-frontend-qt5`

### 3. System Configuration
- **Locale:** 
  - `sudo locale-gen zh_CN.UTF-8`
  - `sudo update-locale LANG=zh_CN.UTF-8`
- **Input Method:**
  - `im-config -n fcitx5`
- **Environment Variables:**
  - Add to `/etc/environment`:
    - `GTK_IM_MODULE=fcitx`
    - `QT_IM_MODULE=fcitx`
    - `XMODIFIERS=@im=fcitx`

## Verification Plan
1. Run the script on a fresh Ubuntu installation (or simulation).
2. Check if `locale` output shows `LANG=zh_CN.UTF-8`.
3. Verify that `fcitx5` is running and the Pinyin input method is available.
4. Ensure environment variables are correctly set in `/etc/environment`.
