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
    # Check if URL already has proxy prefix
    if [[ "$url" == "${GH_PROXY}"* ]]; then
        echo "$url"
        return
    fi
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

# Install gear-lever AppImage to ~/.local/bin
install_gear_lever() {
    local bindir="${XDG_BIN_HOME:-$HOME/.local/bin}"
    local appimage_path="$bindir/GearLever.AppImage"
    local symlink_path="$bindir/gear-lever"

    if [ -x "$appimage_path" ]; then
        return 0
    fi

    echo -e "${YELLOW}gear-lever not found, installing...${NC}"

    # Create bin directory
    mkdir -p "$bindir"

    # Try to get download URL from versions.json first
    local gear_lever_url=""
    if [ -f "$CONFIG_FILE" ]; then
        gear_lever_url=$(jq -r '."gear-lever-appimage".url // ""' "$CONFIG_FILE")
    fi

    # Fallback to gh CLI if versions.json doesn't have valid URL
    if [ -z "$gear_lever_url" ] || [ "$gear_lever_url" = "" ] || [ "$gear_lever_url" = "null" ]; then
        echo "Fetching gear-lever URL from GitHub..."
        gear_lever_url=$(gh release view --repo pkgforge-dev/Gear-Lever-AppImage --json assets 2>/dev/null | \
            jq -r '.assets[] | select(.name | contains("x86_64.AppImage")) | select(.name | contains(".zsync") | not) | .url' | head -1)
    else
        echo "Using gear-lever URL from versions.json"
    fi

    if [ -z "$gear_lever_url" ]; then
        echo -e "${RED}Failed to find gear-lever download URL${NC}"
        echo -e "${YELLOW}Make sure 'gh' CLI is installed and authenticated, or versions.json has gear-lever-appimage entry${NC}"
        exit 1
    fi

    gear_lever_url=$(apply_github_proxy "$gear_lever_url")

    echo "Downloading gear-lever..."
    if ! curl -L -o "$appimage_path" "$gear_lever_url"; then
        echo -e "${RED}Failed to download gear-lever${NC}"
        exit 1
    fi

    chmod +x "$appimage_path"

    # Create symlink for easier access
    ln -sf "$appimage_path" "$symlink_path"

    echo -e "${GREEN}gear-lever installed successfully to $appimage_path${NC}"
}

# Ensure gear-lever is installed and return its path
ensure_gear_lever() {
    local bindir="${XDG_BIN_HOME:-$HOME/.local/bin}"
    local symlink_path="$bindir/gear-lever"
    local appimage_path="$bindir/GearLever.AppImage"

    if [ ! -x "$appimage_path" ]; then
        install_gear_lever
    fi

    # Return the path
    if [ -x "$appimage_path" ]; then
        echo "$appimage_path"
    else
        echo -e "${RED}Error: gear-lever installation failed${NC}" >&2
        exit 1
    fi
}

# Display usage
usage() {
    echo "Usage: $0 [options] [app_name]"
    echo ""
    echo "Options:"
    echo "  --deb <app_name>       Install deb package (using apt install)"
    echo "  --appimage <app_name>  Install AppImage package (using gear-lever)"
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

# Check configuration file
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
fi

# Install dependencies first
install_dependencies

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

# Install AppImage package using gear-lever
install_appimage() {
    local url="$1"
    local app_name="$2"
    local pkg_keyword="$3"

    # Ensure gear-lever is installed and get its path
    local gear_lever
    gear_lever=$(ensure_gear_lever)

    echo -e "${GREEN}Starting installation...${NC}"

    # Download AppImage
    local tmp_dir
    tmp_dir=$(mktemp -d)
    local appimage_file="${tmp_dir}/${app_name}.AppImage"

    echo "Downloading $url ..."
    if ! curl -L -o "$appimage_file" "$url"; then
        echo -e "${RED}Download failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi

    chmod +x "$appimage_file"

    echo "Installing with gear-lever..."
    echo "y" | "$gear_lever" --integrate "$appimage_file" 2>/dev/null || true
    
    # Check if integration was successful by looking for the AppImage in ~/AppImages/
    # gear-lever uses package_keyword as the filename
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
        echo -e "${GREEN}Installation successful${NC}"
        rm -rf "$tmp_dir"
    else
        echo -e "${RED}Installation failed${NC}"
        rm -rf "$tmp_dir"
        exit 1
    fi
}

# Execute installation
case "$FORMAT" in
    deb)
        install_deb "$URL" "$PACKAGE_KEYWORD"
        ;;
    appimage)
        install_appimage "$URL" "$APP_NAME" "$PACKAGE_KEYWORD"
        ;;
    *)
        echo -e "${RED}Error: Unsupported format '$FORMAT'${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Done!${NC}"
