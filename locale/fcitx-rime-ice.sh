#!/bin/bash
set -euo pipefail

# GitHub proxy (optional)
GH_PROXY="${GH_PROXY:-}"

# Install Fcitx5 and Rime
sudo apt install -y fcitx5 fcitx5-rime fcitx5-material-color im-config git

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
  switches:
    - name: ascii_mode
      reset: 1
      states: ["中文", "英文"]
EOF

# Set Fcitx5 theme configuration
FCITX5_CONF_DIR="$HOME/.config/fcitx5/conf"
mkdir -p "$FCITX5_CONF_DIR"

CONF_FILE="$FCITX5_CONF_DIR/classicui.conf"

# 设置或更新配置值的函数（无section格式）
set_config_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  
  # 确保配置文件存在
  [ -f "$file" ] || touch "$file"
  
  # 检查键是否已存在
  if grep -q "^$key=" "$file" 2>/dev/null; then
    # 存在则替换
    sed -i "s|^$key=.*|$key=$value|" "$file"
  else
    # 不存在则添加到文件末尾
    echo "$key=$value" >> "$file"
  fi
}

# 设置主题配置（存在则覆盖，不存在则添加）
set_config_value "$CONF_FILE" "Font" "Noto Sans CJK SC 12"
set_config_value "$CONF_FILE" "Theme" "Material-Color-blue"
set_config_value "$CONF_FILE" "DarkTheme" "Material-Color-teal"

# Set Fcitx5 as default input method
im-config -n fcitx5

# Trigger Rime deployment
fcitx5-remote -r

