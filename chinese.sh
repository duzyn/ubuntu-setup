#!/bin/bash
set -e

# Install Chinese language packs
sudo apt install -y \
    language-pack-zh-hans \
    language-pack-gnome-zh-hans

# Install Fcitx5 and Rime
sudo apt install -y \
    fcitx5 \
    fcitx5-rime \
    im-config \
    git

# Install 雾凇拼音 (rime-ice)
echo "Installing 雾凇拼音 (rime-ice)..."
RIME_DIR="$HOME/.local/share/fcitx5/rime"
mkdir -p "$RIME_DIR"

# Clone rime-ice with gh-proxy
git clone --depth 1 "https://gh-proxy.com/https://github.com/iDvel/rime-ice.git" /tmp/rime-ice

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

echo "Chinese input method setup completed!"
echo "Please log out and log back in to activate the changes."
