#!/bin/bash
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查依赖
for cmd in curl jq gearlever; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}错误：未找到命令 '$cmd'，请先安装。${NC}"
        if [ "$cmd" = "jq" ]; then
            echo -e "${YELLOW}运行: sudo apt install -y jq${NC}"
        elif [ "$cmd" = "gearlever" ]; then
            echo -e "${YELLOW}运行: sudo apt install -y gearlever${NC}"
        fi
        exit 1
    fi
done

# 配置文件
CONFIG_FILE="versions.json"
DEFAULT_FORMAT="deb"

# 显示用法
usage() {
    echo "用法: $0 [选项] [应用名]"
    echo ""
    echo "选项:"
    echo "  --deb <应用名>       安装 deb 包（使用 apt install）"
    echo "  --appimage <应用名>  安装 AppImage 包（使用 gearlever 集成）"
    echo "  --list               列出所有可用的应用"
    echo "  -h, --help           显示此帮助信息"
    echo ""
    echo "如果不指定选项，默认以 deb 格式安装"
    echo ""
    echo "示例:"
    echo "  $0 cherry-studio          # 默认以 deb 安装 cherry-studio"
    echo "  $0 --deb cherry-studio    # 以 deb 安装 cherry-studio"
    echo "  $0 --appimage aya         # 以 appimage 安装 aya"
    echo "  $0 --list                 # 列出所有应用"
}

# 列出所有应用
list_apps() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误：未找到配置文件 $CONFIG_FILE${NC}"
        exit 1
    fi
    
    echo "可用的应用列表:"
    echo ""
    printf "%-20s %-10s %s\n" "应用名" "格式" "版本"
    printf "%s\n" "----------------------------------------"
    
    jq -r 'to_entries[] | [.key, .value.format // "deb", .value.version // "unknown"] | @tsv' "$CONFIG_FILE" | \
    while IFS=$'\t' read -r name format version; do
        printf "%-20s %-10s %s\n" "$name" "$format" "$version"
    done
}

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}错误：未找到配置文件 $CONFIG_FILE${NC}"
    exit 1
fi

# 解析参数
FORMAT=""
APP_NAME=""

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

# 解析选项
case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    --list)
        list_apps
        exit 0
        ;;
    --deb)
        FORMAT="deb"
        if [ -z "${2:-}" ]; then
            echo -e "${RED}错误：请指定应用名${NC}"
            usage
            exit 1
        fi
        APP_NAME="$2"
        ;;
    --appimage)
        FORMAT="appimage"
        if [ -z "${2:-}" ]; then
            echo -e "${RED}错误：请指定应用名${NC}"
            usage
            exit 1
        fi
        APP_NAME="$2"
        ;;
    -*)
        echo -e "${RED}错误：未知选项 $1${NC}"
        usage
        exit 1
        ;;
    *)
        # 无选项，默认 deb 格式
        FORMAT="$DEFAULT_FORMAT"
        APP_NAME="$1"
        ;;
esac

# 检查应用是否存在
if ! jq -e "has(\"$APP_NAME\")" "$CONFIG_FILE" &>/dev/null; then
    echo -e "${RED}错误：未找到应用 '$APP_NAME'${NC}"
    echo -e "${YELLOW}使用 '$0 --list' 查看所有可用应用${NC}"
    exit 1
fi

# 读取应用配置
APP_CONFIG=$(jq -r ".\"$APP_NAME\"" "$CONFIG_FILE")
CONFIG_FORMAT=$(echo "$APP_CONFIG" | jq -r '.format // "deb"')
PACKAGE_KEYWORD=$(echo "$APP_CONFIG" | jq -r '.package_keyword // ""')
VERSION=$(echo "$APP_CONFIG" | jq -r '.version // "unknown"')
URL=$(echo "$APP_CONFIG" | jq -r '.url // ""')

# 如果请求格式与配置格式不匹配，给出警告
if [ "$FORMAT" != "$CONFIG_FORMAT" ]; then
    echo -e "${YELLOW}警告：请求格式 '$FORMAT' 与配置格式 '$CONFIG_FORMAT' 不匹配${NC}"
    echo -e "${YELLOW}将使用配置格式 '$CONFIG_FORMAT'${NC}"
    FORMAT="$CONFIG_FORMAT"
fi

# 检查必要字段
if [ -z "$PACKAGE_KEYWORD" ] || [ -z "$URL" ] || [ "$URL" = "null" ]; then
    echo -e "${RED}错误：应用 '$APP_NAME' 配置不完整${NC}"
    exit 1
fi

echo "====== 安装 ${APP_NAME} ======"
echo "格式: $FORMAT"
echo "版本: $VERSION"
echo "包名: $PACKAGE_KEYWORD"

# 安装 deb 包
install_deb() {
    local url="$1"
    local pkg_keyword="$2"
    
    # 检查是否已安装
    if dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -qx "$pkg_keyword"; then
        INSTALLED_VER=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}已安装 $pkg_keyword 版本 $INSTALLED_VER${NC}"
        
        if [ "$VERSION" != "unknown" ] && [ "$VERSION" != "latest" ]; then
            if dpkg --compare-versions "$INSTALLED_VER" ge "$VERSION" 2>/dev/null; then
                echo -e "${GREEN}当前版本已是最新，无需升级${NC}"
                return 0
            fi
        fi
        echo -e "${YELLOW}开始升级...${NC}"
    else
        echo -e "${GREEN}开始安装...${NC}"
    fi
    
    # 下载并安装
    local tmp_dir=$(mktemp -d)
    local deb_file="${tmp_dir}/package.deb"
    
    echo "下载 $url ..."
    if ! curl -L -o "$deb_file" "$url"; then
        echo -e "${RED}下载失败${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    echo "使用 apt 安装/升级..."
    # 使用 apt install 而不是 dpkg -i，自动处理依赖
    if sudo apt install -y "$deb_file"; then
        echo -e "${GREEN}安装成功${NC}"
    else
        echo -e "${RED}安装失败${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    rm -rf "$tmp_dir"
}

# 安装 AppImage 包
install_appimage() {
    local url="$1"
    local app_name="$2"
    
    # 检查 gearlever 是否安装
    if ! command -v gearlever &>/dev/null; then
        echo -e "${YELLOW}gearlever 未安装，正在安装...${NC}"
        sudo apt install -y gearlever || {
            echo -e "${RED}安装 gearlever 失败${NC}"
            exit 1
        }
    fi
    
    # 检查是否已安装（通过 gearlever list）
    if gearlever list 2>/dev/null | grep -qi "$app_name"; then
        echo -e "${GREEN}已安装 $app_name${NC}"
        echo -e "${YELLOW}如需更新，请先卸载再重新安装${NC}"
        return 0
    fi
    
    echo -e "${GREEN}开始安装...${NC}"
    
    # 下载 AppImage
    local tmp_dir=$(mktemp -d)
    local appimage_file="${tmp_dir}/${app_name}.AppImage"
    
    echo "下载 $url ..."
    if ! curl -L -o "$appimage_file" "$url"; then
        echo -e "${RED}下载失败${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    chmod +x "$appimage_file"
    
    echo "使用 gearlever 集成到系统..."
    if gearlever install "$appimage_file"; then
        echo -e "${GREEN}安装成功${NC}"
    else
        echo -e "${RED}安装失败${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    rm -rf "$tmp_dir"
}

# 执行安装
case "$FORMAT" in
    deb)
        install_deb "$URL" "$PACKAGE_KEYWORD"
        ;;
    appimage)
        install_appimage "$URL" "$APP_NAME"
        ;;
    *)
        echo -e "${RED}错误：不支持的格式 '$FORMAT'${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}完成！${NC}"
