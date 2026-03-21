#!/bin/bash
set -e

# Check if running on Linux Mint 22 (Wilma) or later
if ! command -v lsb_release &>/dev/null; then
    echo "Error: lsb_release not found. Cannot detect OS version."
    exit 1
fi

DISTRIBUTOR=$(lsb_release -is)
RELEASE=$(lsb_release -rs)
CODENAME=$(lsb_release -cs)

# Parse version number
MAJOR_VERSION=$(echo "$RELEASE" | cut -d. -f1)

if [ "$DISTRIBUTOR" != "LinuxMint" ]; then
    echo "Error: This script only supports Linux Mint."
    echo "Detected: $DISTRIBUTOR $RELEASE"
    exit 1
fi

if [ "$MAJOR_VERSION" -lt 22 ]; then
    echo "Error: This script requires Linux Mint 22 or later."
    echo "Detected: Linux Mint $RELEASE ($CODENAME)"
    exit 1
fi

echo "Detected: Linux Mint $RELEASE ($CODENAME) - OK"

# Configure Aliyun mirrors for Linux Mint 22+
echo "Configuring Aliyun mirrors..."

SOURCES_FILE="/etc/apt/sources.list.d/official-package-repositories.list"

# Backup original file
if [ -f "$SOURCES_FILE" ]; then
    sudo cp "$SOURCES_FILE" "${SOURCES_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backup created: ${SOURCES_FILE}.backup.*"
fi

# Write Aliyun mirror configuration
sudo tee "$SOURCES_FILE" > /dev/null << 'EOF'
deb https://mirrors.aliyun.com/linuxmint-packages zena main upstream import backport

deb http://mirrors.aliyun.com/ubuntu noble main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu noble-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu noble-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

echo "Mirror configuration updated to Aliyun."
echo "Updating package lists..."
sudo apt update

# Install Chinese language packs
echo "Installing Chinese language packs..."
sudo apt install -y \
    language-pack-zh-hans \
    language-pack-gnome-zh-hans

# Install Fcitx5 and Rime
echo "Installing Fcitx5 and Rime..."
sudo apt install -y \
    fcitx5 \
    fcitx5-rime \
    im-config \
    git

# Install 雾凇拼音 (rime-ice)
echo "Installing 雾凇拼音 (rime-ice)..."
RIME_DIR="$HOME/.local/share/fcitx5/rime"
mkdir -p "$RIME_DIR"

# Clone rime-ice with optional GH_PROXY
git clone --depth 1 "${GH_PROXY}https://github.com/iDvel/rime-ice.git" /tmp/rime-ice

# Copy configuration files
cp -r /tmp/rime-ice/* "$RIME_DIR/"

# Clean up
rm -rf /tmp/rime-ice

# Set default schema to 雾凇拼音
cat > "$RIME_DIR/default.custom.yaml" << 'EOF'
patch:
  schema_list:
    - schema: rime_ice
EOF

# Generate locale and update system settings
sudo locale-gen zh_CN.UTF-8
sudo update-locale LANG=zh_CN.UTF-8

# Set Fcitx5 as default input method
im-config -n fcitx5

# Trigger Rime deployment
echo "Deploying Rime schema..."
if command -v fcitx5-remote &>/dev/null; then
    fcitx5-remote -r 2>/dev/null || true
fi

echo "=========================================="
echo "Chinese input method setup completed!"
echo "=========================================="
echo "Changes made:"
echo "  - Switched to Aliyun mirrors"
echo "  - Installed Chinese language packs"
echo "  - Installed Fcitx5 + Rime + 雾凇拼音"
echo ""
echo "Please log out and log back in to activate the changes."
