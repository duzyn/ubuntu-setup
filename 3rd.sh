#!/bin/bash
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="versions.json"
DEFAULT_FORMAT="deb"

# Get GitHub proxy from environment
GH_PROXY="${GH_PROXY:-}"

# Apply GitHub proxy to URL if it's a GitHub URL
apply_github_proxy() {
    local url="$1"
    if [[ "$url" == *"github.com"* ]] && [[ -n "$GH_PROXY" ]]; then
        echo "${GH_PROXY}${url}"
    else
        echo "$url"
    fi
}

# Auto-install dependencies
install_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}Installing missing dependencies: ${missing_deps[*]}${NC}"
        sudo apt update
        sudo apt install -y "${missing_deps[@]}"
    fi
}

# Install AppImageLauncher from versions.json
install_appimagelauncher() {
    if command -v ail-cli &>/dev/null; then
        return 0
    fi
    
    echo -e "${YELLOW}AppImageLauncher not found, installing...${NC}"
    
    # Get AppImageLauncher URL from versions.json
    local ail_url
    ail_url=$(jq -r '.appimagelauncher.url // empty' "$CONFIG_FILE")
    
    if [ -z "$ail_url" ] || [ "$ail_url" = "null" ]; then
        echo -e "${RED}Error: AppImageLauncher URL not found in $CONFIG_FILE${NC}"
        exit 1
    fi
    
    # Apply GitHub proxy
    ail_url=$(apply_github_proxy "$ail_url")
    
    local tmp_dir=$(mktemp -d)
    
    echo "Downloading AppImageLauncher..."
    if ! curl -L -o "$tmp_dir/appimagelauncher.deb" "$ail_url"; then
        echo -e "${RED}Failed to download AppImageLauncher${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    echo "Installing AppImageLauncher..."
    if ! sudo apt install -y "$tmp_dir/appimagelauncher.deb"; then
        echo -e "${RED}Failed to install AppImageLauncher${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    rm -rf "$tmp_dir"
    echo -e "${GREEN}AppImageLauncher installed successfully${NC}"
}

# Display usage
usage() {
    echo "Usage: $0 [options] [app_name]"
    echo ""
    echo "Options:"
    echo "  --deb <app_name>       Install deb package (using apt install)"
    echo "  --appimage <app_name>  Install AppImage package (using AppImageLauncher)"
    echo "  --list                 List all available applications"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "If no option is specified, default to deb format installation"
    echo ""
    echo "Examples:"
    echo "  $0 cherry-studio          # Install cherry-studio with deb (default)"
    echo "  $0 --deb cherry-studio    # Install cherry-studio with deb"
    echo "  $0 --appimage aya         # Install aya with appimage"
    echo "  $0 --list                 # List all applications"
}

# List all applications
list_apps() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
        exit 1
    fi
    
    echo "Available applications list:"
    echo ""
    printf "%-20s %-10s %s\n" "App Name" "Format" "Version"
    printf "%s\n" "----------------------------------------"
    
    jq -r 'to_entries[] | [.key, .value.format // "deb", .value.version // "unknown"] | @tsv' "$CONFIG_FILE" | \
    while IFS=$'\t' read -r name format version; do
        printf "%-20s %-10s %s\n" "$name" "$format" "$version"
    done
}

# Check configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
fi

# Install dependencies first
install_dependencies

# Parse arguments
FORMAT=""
APP_NAME=""

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

# Parse options
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
            echo -e "${RED}Error: Please specify application name${NC}"
            usage
            exit 1
        fi
        APP_NAME="$2"
        ;;
    --appimage)
        FORMAT="appimage"
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Please specify application name${NC}"
            usage
            exit 1
        fi
        APP_NAME="$2"
        ;;
    -*)
        echo -e "${RED}Error: Unknown option $1${NC}"
        usage
        exit 1
        ;;
    *)
        # No option, default to deb format
        FORMAT="$DEFAULT_FORMAT"
        APP_NAME="$1"
        ;;
esac

# Check if application exists
if ! jq -e "has(\"$APP_NAME\")" "$CONFIG_FILE" &>/dev/null; then
    echo -e "${RED}Error: Application '$APP_NAME' not found${NC}"
    echo -e "${YELLOW}Use '$0 --list' to view all available applications${NC}"
    exit 1
fi

# Read application configuration
APP_CONFIG=$(jq -r ".\"$APP_NAME\"" "$CONFIG_FILE")
CONFIG_FORMAT=$(echo "$APP_CONFIG" | jq -r '.format // "deb"')
PACKAGE_KEYWORD=$(echo "$APP_CONFIG" | jq -r '.package_keyword // ""')
VERSION=$(echo "$APP_CONFIG" | jq -r '.version // "unknown"')
URL=$(echo "$APP_CONFIG" | jq -r '.url // ""')

# Apply GitHub proxy to URL
URL=$(apply_github_proxy "$URL")

# If requested format does not match config format, give warning
if [ "$FORMAT" != "$CONFIG_FORMAT" ]; then
    echo -e "${YELLOW}Warning: Requested format '$FORMAT' does not match config format '$CONFIG_FORMAT'${NC}"
    echo -e "${YELLOW}Will use config format '$CONFIG_FORMAT'${NC}"
    FORMAT="$CONFIG_FORMAT"
fi

# Check required fields
if [ -z "$PACKAGE_KEYWORD" ] || [ -z "$URL" ] || [ "$URL" = "null" ]; then
    echo -e "${RED}Error: Application '$APP_NAME' configuration incomplete${NC}"
    exit 1
fi

echo "====== Installing ${APP_NAME} ======"
echo "Format: $FORMAT"
echo "Version: $VERSION"
echo "Package: $PACKAGE_KEYWORD"

# Install deb package
install_deb() {
    local url="$1"
    local pkg_keyword="$2"
    
    # Check if already installed
    if dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -qx "$pkg_keyword"; then
        INSTALLED_VER=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}Installed $pkg_keyword version $INSTALLED_VER${NC}"
        
        if [ "$VERSION" != "unknown" ] && [ "$VERSION" != "latest" ]; then
            if dpkg --compare-versions "$INSTALLED_VER" ge "$VERSION" 2>/dev/null; then
                echo -e "${GREEN}Current version is up to date, no upgrade needed${NC}"
                return 0
            fi
        fi
        echo -e "${YELLOW}Starting upgrade...${NC}"
    else
        echo -e "${GREEN}Starting installation...${NC}"
    fi
    
    # Download and install
    local tmp_dir=$(mktemp -d)
    local deb_file="${tmp_dir}/package.deb"
    
    echo "Downloading $url ..."
    if ! curl -L -o "$deb_file" "$url"; then
        echo -e "${RED}Download failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    echo "Installing with apt..."
    # Use apt install instead of dpkg -i to auto-resolve dependencies
    if sudo apt install -y "$deb_file"; then
        echo -e "${GREEN}Installation successful${NC}"
    else
        echo -e "${RED}Installation failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    rm -rf "$tmp_dir"
}

# Install AppImage package
install_appimage() {
    local url="$1"
    local app_name="$2"
    
    # Ensure AppImageLauncher is installed
    install_appimagelauncher
    
    # Check if already installed (check in ~/Applications)
    local app_dir="$HOME/Applications"
    if [ -d "$app_dir" ] && ls "$app_dir" | grep -qi "$app_name"; then
        echo -e "${GREEN}Installed $app_name${NC}"
        echo -e "${YELLOW}To update, uninstall first and then reinstall${NC}"
        return 0
    fi
    
    echo -e "${GREEN}Starting installation...${NC}"
    
    # Download AppImage
    local tmp_dir=$(mktemp -d)
    local appimage_file="${tmp_dir}/${app_name}.AppImage"
    
    echo "Downloading $url ..."
    if ! curl -L -o "$appimage_file" "$url"; then
        echo -e "${RED}Download failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    chmod +x "$appimage_file"
    
    echo "Installing with AppImageLauncher..."
    if ail-cli integrate "$appimage_file"; then
        echo -e "${GREEN}Installation successful${NC}"
    else
        echo -e "${RED}Installation failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    rm -rf "$tmp_dir"
}

# Execute installation
case "$FORMAT" in
    deb)
        install_deb "$URL" "$PACKAGE_KEYWORD"
        ;;
    appimage)
        install_appimage "$URL" "$APP_NAME"
        ;;
    *)
        echo -e "${RED}Error: Unsupported format '$FORMAT'${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Done!${NC}"
