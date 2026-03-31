#!/bin/bash
set -euo pipefail

# GitHub proxy (optional)
GH_PROXY="${GH_PROXY:-}"

# Install Fcitx5 and Rime
sudo apt install -y fcitx5 fcitx5-rime im-config git

# Install rime-ice
RIME_DIR="$HOME/.local/share/fcitx5/rime"

[ -d "$RIME_DIR" ] && \
  git -C "$RIME_DIR" pull || \
  git clone --depth 1 "${GH_PROXY}https://github.com/iDvel/rime-ice.git" "$RIME_DIR"

# Set default schema to rime-ice
cat > "$RIME_DIR/default.custom.yaml" << 'EOF'
patch:
  schema_list:
  - schema: rime_ice
EOF

# Set Fcitx5 as default input method
im-config -n fcitx5

# Trigger Rime deployment
fcitx5-remote -r
