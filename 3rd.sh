#!/bin/bash
set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file
CONFIG_FILE="versions.json"
DEFAULT_FORMAT="deb"

# Get GitHub proxy from environment
GH_PROXY="${GH_PROXY:-}"

# Global arrays for update tracking
declare -a APPS_TO_UPDATE=()
declare -a APPS_NEED_INSTALL=()

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

# Check deb package for updates
# Returns: 0=up-to-date, 1=needs-install, 2=needs-update
check_deb_update() {
    local pkg_keyword="$1"
    local available_version="$2"
    
    if dpkg-query -W "$pkg_keyword" &>/dev/null; then
        local installed_version
        installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")

        if [ "$installed_version" != "unknown" ]; then
            if dpkg --compare-versions "$installed_version" ge "$available_version" 2>/dev/null; then
                return 0  # up-to-date
            else
                return 2  # needs-update
            fi
        fi
    fi

    return 1  # needs-install
}

# Check AppImage for updates
# Returns: 0=installed, 1=needs-install
check_appimage_update() {
    local pkg_keyword="$1"
    local available_version="$2"
    
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
        return 0  # installed
    else
        return 1  # needs-install
    fi
}

# Main function to check all apps for updates
check_all_updates() {
    echo -e "${BLUE}====== Checking for updates ======${NC}"
    echo ""
    
    local needs_update=0
    local needs_install=0
    local checked=0
    
    # Get list of app names (excluding gear-lever-appimage)
    local app_names
    app_names=$(jq -r 'keys[] | select(. != "gear-lever-appimage")' "$CONFIG_FILE")
    
    for app_name in $app_names; do
        local config_format pkg_keyword available_version result
        
        config_format=$(jq -r ".\"$app_name\".format // \"deb\"" "$CONFIG_FILE")
        pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
        available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
        
        if [ -z "$pkg_keyword" ] || [ "$pkg_keyword" = "null" ]; then
            continue
        fi
        
        checked=$((checked + 1))
        
        if [ "$config_format" = "deb" ]; then
            { check_deb_update "$pkg_keyword" "$available_version"; } && result=0 || result=$?
            
            case $result in
                0)
                    echo -e "${GREEN}[OK]${NC}   $app_name (deb) - up to date ($available_version)"
                    ;;
                1)
                    echo -e "${YELLOW}[NEW]${NC}  $app_name (deb) - needs install ($available_version)"
                    APPS_NEED_INSTALL+=("$app_name")
                    needs_install=$((needs_install + 1))
                    ;;
                2)
                    echo -e "${RED}[UPG]${NC}  $app_name (deb) - needs update ($available_version)"
                    APPS_TO_UPDATE+=("$app_name")
                    needs_update=$((needs_update + 1))
                    ;;
            esac
        elif [ "$config_format" = "appimage" ]; then
            { check_appimage_update "$pkg_keyword" "$available_version"; } && result=0 || result=$?
            
            case $result in
                0)
                    echo -e "${GREEN}[OK]${NC}   $app_name (AppImage) - installed"
                    ;;
                1)
                    echo -e "${YELLOW}[NEW]${NC}  $app_name (AppImage) - needs install ($available_version)"
                    APPS_NEED_INSTALL+=("$app_name")
                    needs_install=$((needs_install + 1))
                    ;;
            esac
        fi
    done
    
    echo ""
    echo -e "${BLUE}====== Summary ======${NC}"
    echo "Checked: $checked apps"
    echo -e "Up to date: $((checked - needs_update - needs_install))"
    
    if [ $needs_update -gt 0 ]; then
        echo -e "${RED}Need update: $needs_update${NC}"
    fi
    
    if [ $needs_install -gt 0 ]; then
        echo -e "${YELLOW}Need install: $needs_install${NC}"
    fi
    
    # Ask for confirmation before installing/updating
    if [ $((needs_update + needs_install)) -gt 0 ]; then
        echo ""
        echo -n "Do you want to install/update these apps? [y/N]: "
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Install/update all needed apps
            for app in "${APPS_TO_UPDATE[@]}" "${APPS_NEED_INSTALL[@]}"; do
                echo ""
                echo -e "${BLUE}====== Installing/Updating: $app ======${NC}"
                "$0" "$app"
            done
        else
            echo "Skipped."
        fi
    fi
}

# Display usage
usage() {
    echo "Usage: $0 [options] [app_name]"
    echo ""
    echo "Options:"
    echo "  --check                  Check all apps for updates"
    echo "  --install <app_name>     Install specific app"
    echo "  --deb <app_name>         Install deb package (using apt install)"
    echo "  --appimage <app_name>    Install AppImage package (using gear-lever)"
    echo "  --list                   List all available applications"
    echo "  -h, --help               Display this help message"
    echo ""
    echo "If no option is specified, default behavior is to check all apps for updates"
    echo ""
    echo "Examples:"
    echo "  $0                       # Check all apps for updates"
    echo "  $0 --check               # Check all apps for updates"
    echo "  $0 --install cherry-studio  # Install cherry-studio"
    echo "  $0 --deb cherry-studio   # Install cherry-studio with deb"
    echo "  $0 --appimage aya        # Install aya with appimage"
    echo "  $0 --list                # List all applications"
}

# List all applications with status
list_apps() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
        exit 1
    fi
    
    echo "Available applications list:"
    echo ""
    printf "%-20s %-10s %-15s %s\n" "App Name" "Format" "Status" "Version"
    printf "%s\n" "---------------------------------------------------------------------"
    
    while IFS= read -r app_json; do
        local app_name
        app_name=$(echo "$app_json" | jq -r '.key')
        
        local config_format pkg_keyword available_version status
        
        config_format=$(echo "$app_json" | jq -r '.value.format // "deb"')
        pkg_keyword=$(echo "$app_json" | jq -r '.value.package_keyword // ""')
        available_version=$(echo "$app_json" | jq -r '.value.version // "unknown"')
        
        # Skip gear-lever-appimage in list
        if [ "$app_name" = "gear-lever-appimage" ]; then
            continue
        fi
        
        # Check status
        if [ "$config_format" = "deb" ]; then
            if dpkg-query -W "$pkg_keyword" &>/dev/null; then
                status="installed"
            else
                status="not installed"
            fi
        elif [ "$config_format" = "appimage" ]; then
            if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
                status="installed"
            else
                status="not installed"
            fi
        fi
        
        printf "%-20s %-10s %-15s %s\n" "$app_name" "$config_format" "$status" "$available_version"
    done < <(jq -r 'to_entries[] | @json' "$CONFIG_FILE")
}

# Parse arguments
FORMAT=""
APP_NAME=""
COMMAND="check_all_updates"

# Check if no arguments provided - default to check_all_updates
if [ $# -eq 0 ]; then
    COMMAND="check_all_updates"
else
    # Parse options
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --check)
            COMMAND="check_all_updates"
            ;;
        --list)
            COMMAND="list_apps"
            ;;
        --install)
            COMMAND="install"
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Please specify application name${NC}"
                usage
                exit 1
            fi
            APP_NAME="$2"
            ;;
        --deb)
            COMMAND="install"
            FORMAT="deb"
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Please specify application name${NC}"
                usage
                exit 1
            fi
            APP_NAME="$2"
            ;;
        --appimage)
            COMMAND="install"
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
            # Default to install with deb format
            COMMAND="install"
            FORMAT="$DEFAULT_FORMAT"
            APP_NAME="$1"
            ;;
    esac
fi

# Execute command
case "$COMMAND" in
    check_all_updates)
        if [ ! -f "$CONFIG_FILE" ]; then
            echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
            exit 1
        fi
        install_dependencies
        check_all_updates
        exit 0
        ;;
    list_apps)
        list_apps
        exit 0
        ;;
    install)
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
        
        # If format not specified, use config format
        if [ -z "$FORMAT" ]; then
            FORMAT="$CONFIG_FORMAT"
        fi
        
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
            if dpkg-query -W "$pkg_keyword" &>/dev/null; then
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
        ;;
esac
