#!/bin/bash
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置文件
CONFIG_FILE="${1:-versions.json}"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}请以 root 权限运行此脚本（使用 sudo）。${NC}"
    exit 1
fi

# 依赖检查
for cmd in curl dpkg awk grep sed jq; do
    if ! command -v $cmd &>/dev/null; then
        echo -e "${RED}错误：未找到命令 '$cmd'，请先安装。${NC}"
        exit 1
    fi
done

# 配置文件检查
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误：未找到配置文件 $CONFIG_FILE${NC}"
    exit 1
fi

# 获取 Ubuntu 版本（如 24.04）
if command -v lsb_release &>/dev/null; then
    UBUNTU_VERSION=$(lsb_release -rs)
else
    echo -e "${RED}错误：未找到 lsb_release 命令，无法检测 Ubuntu 版本。${NC}"
    exit 1
fi
echo "检测到 Ubuntu 版本: $UBUNTU_VERSION"

# 安装/升级通用函数
# 参数: 应用名称(显示用) 包名关键字 目标版本 下载地址
install_or_upgrade() {
    local name="$1"
    local keyword="$2"
    local target_version="$3"
    local download_url="$4"

    echo -e "\n====== 处理 ${name} ======"

    # 检查是否已安装（通过包名关键字匹配）
    local installed_info=$(dpkg-query -W -f='${Package} ${Version}\n' 2>/dev/null | grep -i "$keyword" | head -1)
    local installed_version=""
    local pkg_name=""

    if [ -n "$installed_info" ]; then
        pkg_name=$(echo "$installed_info" | awk '{print $1}')
        installed_version=$(echo "$installed_info" | awk '{print $2}')
        echo -e "${GREEN}已安装 $pkg_name 版本 $installed_version${NC}"
    else
        echo -e "${YELLOW}未检测到 $keyword 的安装记录${NC}"
    fi

    # 决定是否需要安装/升级
    if [ -z "$installed_version" ]; then
        echo -e "${GREEN}开始安装 $name ...${NC}"
        do_install "$download_url"
    else
        # 比较版本号（使用 dpkg 原生的比较工具）
        if dpkg --compare-versions "$installed_version" lt "$target_version"; then
            echo -e "${GREEN}当前版本 $installed_version 低于目标版本 $target_version，开始升级 ...${NC}"
            do_install "$download_url"
        else
            echo -e "${GREEN}当前版本 $installed_version 已满足要求（>= $target_version），无需操作。${NC}"
        fi
    fi
}

# 实际下载并安装 deb 包
do_install() {
    local url="$1"
    local tmp_dir=$(mktemp -d)
    local deb_file="${tmp_dir}/package.deb"

    echo "下载 $url ..."
    if ! curl -L -o "$deb_file" "$url"; then
        echo -e "${RED}下载失败${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi

    echo "安装/升级中 ..."
    if dpkg -i "$deb_file"; then
        echo -e "${GREEN}安装成功${NC}"
    else
        echo -e "${YELLOW}尝试修复依赖 ...${NC}"
        apt-get install -f -y
        if dpkg -i "$deb_file"; then
            echo -e "${GREEN}安装成功（已修复依赖）${NC}"
        else
            echo -e "${RED}安装失败${NC}"
            rm -rf "$tmp_dir"
            exit 1
        fi
    fi

    rm -rf "$tmp_dir"
}

# 主处理：遍历 versions.json 中的所有应用
echo "读取配置文件 $CONFIG_FILE ..."
APP_NAMES=$(jq -r 'keys[]' "$CONFIG_FILE")

for APP in $APP_NAMES; do
    echo -e "\n====== 检查应用: $APP ======"

    # 获取包名关键字（所有应用都有此字段）
    PKG_KEYWORD=$(jq -r ".\"$APP\".package_keyword // \"\"" "$CONFIG_FILE")
    if [ -z "$PKG_KEYWORD" ]; then
        echo -e "${YELLOW}警告：应用 $APP 缺少 package_keyword，跳过。${NC}"
        continue
    fi

    # 判断是否为多发行版应用
    MULTI=$(jq -r ".\"$APP\".multi // false" "$CONFIG_FILE")
    if [ "$MULTI" = "true" ]; then
        # 多发行版应用：根据 Ubuntu 版本获取对应条目
        ENTRY=$(jq -r ".\"$APP\".versions.\"$UBUNTU_VERSION\"" "$CONFIG_FILE")
        if [ "$ENTRY" = "null" ]; then
            echo -e "${YELLOW}警告：应用 $APP 在 Ubuntu $UBUNTU_VERSION 上无对应包，跳过。${NC}"
            continue
        fi
        VERSION=$(echo "$ENTRY" | jq -r '.version')
        URL=$(echo "$ENTRY" | jq -r '.url')
        install_or_upgrade "$APP" "$PKG_KEYWORD" "$VERSION" "$URL"
    else
        # 普通应用：直接获取 version 和 url
        VERSION=$(jq -r ".\"$APP\".version // \"unknown\"" "$CONFIG_FILE")
        URL=$(jq -r ".\"$APP\".url // \"\"" "$CONFIG_FILE")
        if [ "$VERSION" = "null" ] || [ "$URL" = "null" ] || [ -z "$URL" ]; then
            echo -e "${YELLOW}警告：应用 $APP 配置不完整，跳过。${NC}"
            continue
        fi
        install_or_upgrade "$APP" "$PKG_KEYWORD" "$VERSION" "$URL"
    fi
done

echo -e "\n${GREEN}所有软件处理完成。${NC}"