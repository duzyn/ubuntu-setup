# Chinese Script Improvement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor `desktop/chinese.sh` to improve error handling, remove redundant updates, and enhance idempotency for environment variables.

**Architecture:** Use `set -e` for robust script execution, remove `apt update` (handled by parent `setup.sh`), and use a `for` loop to check/append individual environment variables in `/etc/environment`.

**Tech Stack:** Bash

---

### Task 1: Refactor `desktop/chinese.sh`

**Files:**
- Modify: `desktop/chinese.sh`

**Step 1: Read the existing file**
Read `desktop/chinese.sh` to ensure context.

**Step 2: Update the file with the improved implementation**

```bash
#!/bin/bash
set -e

# Install Chinese language packs
sudo apt install -y language-pack-zh-hans language-pack-gnome-zh-hans

# Install Fcitx5 and Pinyin
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 fcitx5-frontend-qt5 im-config

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8

# Set Fcitx5 as default input method
im-config -n fcitx5

# Configure environment variables
for var in "GTK_IM_MODULE=fcitx" "QT_IM_MODULE=fcitx" "XMODIFIERS=@im=fcitx"; do
    if ! grep -q "^${var}$" /etc/environment; then
        echo "$var" | sudo tee -a /etc/environment
    fi
done
```

**Step 3: Verify the script syntax**
Run: `bash -n desktop/chinese.sh`
Expected: No output (success).

**Step 4: Commit the changes**

Run:
```bash
git add desktop/chinese.sh
git commit -m "refactor(desktop): improve chinese.sh script quality

- Add set -e for better error handling
- Remove redundant sudo apt update
- Use loop for idempotent environment variable configuration"
```
