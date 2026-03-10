# Chinese Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a script to install Simplified Chinese language packs, Fcitx5 with Pinyin, and set the system locale to zh_CN.UTF-8.

**Architecture:** Add a modular script `desktop/chinese.sh` that will be automatically sourced by `desktop.sh`.

**Tech Stack:** Bash, apt, fcitx5, im-config.

---

### Task 1: Create the Chinese Support Script

**Files:**
- Create: `desktop/chinese.sh`

**Step 1: Write the implementation**

```bash
#!/bin/bash

# Install Chinese language packs
sudo apt update
sudo apt install -y language-pack-zh-hans language-pack-gnome-zh-hans

# Install Fcitx5 and Pinyin
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8

# Set Fcitx5 as default input method
im-config -n fcitx5

# Configure environment variables
if ! grep -q "GTK_IM_MODULE=fcitx" /etc/environment; then
    echo "GTK_IM_MODULE=fcitx" | sudo tee -a /etc/environment
    echo "QT_IM_MODULE=fcitx" | sudo tee -a /etc/environment
    echo "XMODIFIERS=@im=fcitx" | sudo tee -a /etc/environment
fi
```

**Step 2: Verify script existence**

Run: `ls desktop/chinese.sh`
Expected: `desktop/chinese.sh`

**Step 3: Commit**

```bash
git add desktop/chinese.sh
git commit -m "feat: add chinese language and fcitx5 pinyin support"
```

### Task 2: Verification

**Step 1: Run the script (Simulation/Check)**

Run: `bash -n desktop/chinese.sh`
Expected: No output (syntax check passes)

**Step 2: Verify integration**

Run: `grep "source \$installer" desktop.sh`
Expected: `for installer in ./desktop/*.sh; do source $installer; done`
