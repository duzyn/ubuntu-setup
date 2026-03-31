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
# Returns: 0=up-to-date, 1=not-installed, 2=needs-update
check_deb_update() {
  local pkg_keyword="$1"
  local available_version="$2"

  if dpkg-query -W "$pkg_keyword" &>/dev/null; then
    local installed_version
    installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")

    if [ "$installed_version" != "unknown" ]; then
      local installed_upstream available_upstream
      installed_upstream=$(echo "$installed_version" | sed 's/-.*//')
      available_upstream=$(echo "$available_version" | sed 's/-.*//')

      if dpkg --compare-versions "$available_upstream" le "$installed_upstream" 2>/dev/null; then
        return 0
      fi

      if [[ "$installed_upstream" == "$available_upstream"* ]] || [[ "$available_upstream" == "$installed_upstream"* ]]; then
        return 0
      fi

      return 2
    fi
  fi

  return 1
}

# Check AppImage for updates
# Returns: 0=installed, 1=not-installed
check_appimage_installed() {
  local pkg_keyword="$1"

  if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
    return 0  # installed
  else
    return 1  # not-installed
  fi
}


check_all_updates() {
  echo -e "${BLUE}====== Checking installed apps for updates ======${NC}"
  echo ""

  local needs_update=0
  local checked=0
  local installed_count=0

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
      result=0
      check_deb_update "$pkg_keyword" "$available_version" || result=$?

      case $result in
        0)
          installed_count=$((installed_count + 1))
          echo -e "${GREEN}[OK]${NC}   $app_name (deb) - up to date ($available_version)"
          ;;
        1)
          ;;
        2)
          installed_count=$((installed_count + 1))
          local installed_version
          installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null | sed 's/-.*//' || echo "unknown")
          echo -e "${RED}[UPG]${NC}  $app_name (deb) - needs update ($installed_version -> $available_version)"
          APPS_TO_UPDATE+=("$app_name")
          needs_update=$((needs_update + 1))
          ;;
      esac
    elif [ "$config_format" = "appimage" ]; then
      result=0
      check_appimage_installed "$pkg_keyword" || result=$?

      case $result in
        0)
          installed_count=$((installed_count + 1))
          echo -e "${GREEN}[OK]${NC}   $app_name (AppImage) - installed"
          ;;
        1)
          ;;
      esac
    fi
  done

  echo ""
  echo -e "${BLUE}====== Summary ======${NC}"
  echo "Total apps in config: $checked"
  echo "Installed apps checked: $installed_count"

  if [ $needs_update -gt 0 ]; then
    echo -e "${RED}Need update: $needs_update${NC}"
  fi

  # Ask for confirmation before updating
  if [ $needs_update -gt 0 ]; then
    echo ""
    echo -n "Do you want to update these apps? [y/N]: "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
      # Update all needed apps
      for app in "${APPS_TO_UPDATE[@]}"; do
        echo ""
        echo -e "${BLUE}====== Updating: $app ======${NC}"
        # Get the format from config
        local app_format
        app_format=$(jq -r ".\"$app\".format // \"deb\"" "$CONFIG_FILE")
        if [ "$app_format" = "deb" ]; then
          "$0" install --deb "$app"
        elif [ "$app_format" = "appimage" ]; then
          "$0" install --appimage "$app"
        fi
      done
    else
      echo "Skipped."
    fi
  else
    echo -e "${GREEN}All installed apps are up to date!${NC}"
  fi
}

# Display usage
usage() {
  echo "Usage: $0 <command> [options]"
  echo ""
  echo "Commands:"
  echo "  help                              Show this help message"
  echo "  install --deb <app>               Install deb package"
  echo "  install --appimage <app>          Install AppImage package"
  echo "  install --deb <app> --dry-run     Simulate deb installation"
  echo "  install --appimage <app> --dry-run Simulate AppImage installation"
  echo "  list                              List all apps in versions.json"
  echo "  list --installed                  List installed apps"
  echo "  list --outdated                   List installed apps that need update"
  echo "  upgrade                           Upgrade all outdated apps"
  echo ""
  echo "Examples:"
  echo "  $0 help                           # Show help"
  echo "  $0 install --deb cherry-studio    # Install cherry-studio with deb"
  echo "  $0 install --appimage aya         # Install aya with AppImage"
  echo "  $0 list                           # List all available apps"
  echo "  $0 list --installed               # List installed apps"
  echo "  $0 list --outdated                # List apps that need update"
  echo "  $0 upgrade                        # Upgrade all outdated apps"
}

# List all applications with status
list_apps() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Available applications list:"
  echo ""
  printf "%-25s %-10s %-12s %-15s\n" "软件名" "类型" "状态" "最新版本"
  printf "%s\n" "-------------------------------------------------------------------------"
  
  # Get sorted DEB apps (excluding gear-lever-appimage)
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps (excluding gear-lever-appimage)
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword available_version status
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    # Check status
    if dpkg-query -W "$pkg_keyword" &>/dev/null; then
      status="installed"
    else
      status="not installed"
    fi
    
    printf "%-25s %-10s %-12s %-15s\n" "$app_name" "DEB" "$status" "$available_version"
  done
  
  # Process AppImage apps
  for app_name in $appimage_apps; do
    local pkg_keyword available_version status
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    # Check status
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
      status="installed"
    else
      status="not installed"
    fi
    
    printf "%-25s %-10s %-12s %-15s\n" "$app_name" "AppImage" "$status" "$available_version"
  done
}

# List installed apps only
list_installed() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Installed applications:"
  echo ""
  printf "%-25s %-10s %-15s\n" "软件名" "类型" "当前版本"
  printf "%s\n" "--------------------------------------------------------"
  
  local has_installed=0
  
  # Get sorted DEB apps (excluding gear-lever-appimage)
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps (excluding gear-lever-appimage)
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword installed_version
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    
    if dpkg-query -W "$pkg_keyword" &>/dev/null; then
      installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")
      printf "%-25s %-10s %-15s\n" "$app_name" "DEB" "$installed_version"
      has_installed=1
    fi
  done
  
  # Process AppImage apps
  for app_name in $appimage_apps; do
    local pkg_keyword
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
      printf "%-25s %-10s %-15s\n" "$app_name" "AppImage" "installed"
      has_installed=1
    fi
  done
  
  if [ $has_installed -eq 0 ]; then
    echo "No apps installed."
  fi
}

# List outdated apps
list_outdated() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Apps that need updates:"
  echo ""
  printf "%-25s %-10s %-35s\n" "软件名" "类型" "版本"
  printf "%s\n" "----------------------------------------------------------------------"
  
  local has_outdated=0
  
  # Get sorted DEB apps (excluding gear-lever-appimage)
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps (excluding gear-lever-appimage)
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword available_version result
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    result=0
    check_deb_update "$pkg_keyword" "$available_version" || result=$?
    
    if [ $result -eq 2 ]; then
      local installed_version
      installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null | sed 's/-.*//' || echo "unknown")
      printf "%-25s %-10s %-35s\n" "$app_name" "DEB" "($installed_version -> $available_version)"
      APPS_TO_UPDATE+=("$app_name")
      has_outdated=1
    fi
  done
  
  # AppImage version detection is not supported yet
  
  if [ $has_outdated -eq 0 ]; then
    echo "All installed apps are up to date."
  fi
}

# Parse arguments
FORMAT=""
APP_NAME=""
COMMAND=""
DRY_RUN=false
LIST_MODE=""  # "", "installed", "outdated"

# First argument is the command
if [ $# -eq 0 ]; then
  usage
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  help|-h|--help)
    usage
    exit 0
    ;;
  
  install)
    # Must specify --deb or --appimage
    if [ $# -eq 0 ]; then
      echo -e "${RED}Error: Please specify --deb or --appimage${NC}"
      usage
      exit 1
    fi
    
    case "$1" in
      --deb)
        FORMAT="deb"
        shift
        ;;
      --appimage)
        FORMAT="appimage"
        shift
        ;;
      *)
        echo -e "${RED}Error: Must specify --deb or --appimage${NC}"
        usage
        exit 1
        ;;
    esac
    
    # Parse remaining arguments
    while [ $# -gt 0 ]; do
      case "$1" in
        --dry-run)
          DRY_RUN=true
          shift
          ;;
        -*)
          echo -e "${RED}Error: Unknown option $1${NC}"
          usage
          exit 1
          ;;
        *)
          if [ -z "$APP_NAME" ]; then
            APP_NAME="$1"
          fi
          shift
          ;;
      esac
    done
    
    if [ -z "$APP_NAME" ]; then
      echo -e "${RED}Error: Please specify application name${NC}"
      usage
      exit 1
    fi
    ;;
  
  list)
    # Check for subcommand
    if [ $# -gt 0 ]; then
      case "$1" in
        --installed)
          LIST_MODE="installed"
          shift
          ;;
        --outdated)
          LIST_MODE="outdated"
          shift
          ;;
        *)
          echo -e "${RED}Error: Unknown option $1${NC}"
          usage
          exit 1
          ;;
      esac
    fi
    ;;
  
  upgrade)
    # Upgrade all outdated apps
    ;;
  
  *)
    echo -e "${RED}Error: Unknown command '$COMMAND'${NC}"
    usage
    exit 1
    ;;
esac

# Execute command
case "$COMMAND" in
  list)
    if [ "$LIST_MODE" = "" ]; then
      list_apps
    elif [ "$LIST_MODE" = "installed" ]; then
      list_installed
    elif [ "$LIST_MODE" = "outdated" ]; then
      list_outdated
    fi
    exit 0
    ;;
  upgrade)
    if [ ! -f "$CONFIG_FILE" ]; then
      echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
      exit 1
    fi
    install_dependencies
    check_all_updates
    exit 0
    ;;
  install)
    # Check configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
      echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
      exit 1
    fi
    
    if [ "$DRY_RUN" != true ]; then
      install_dependencies
    fi
    
    # Check if application exists
    if ! jq -e "has(\"$APP_NAME\")" "$CONFIG_FILE" &>/dev/null; then
      echo -e "${RED}Error: Application '$APP_NAME' not found${NC}"
      echo -e "${YELLOW}Use '$0 list' to view all available applications${NC}"
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
        if [ "$DRY_RUN" = true ]; then
          echo -e "${YELLOW}[DRY-RUN] Would upgrade $pkg_keyword to version $VERSION${NC}"
        else
          echo -e "${YELLOW}Starting upgrade...${NC}"
        fi
      else
        if [ "$DRY_RUN" = true ]; then
          echo -e "${YELLOW}[DRY-RUN] Would install $pkg_keyword version $VERSION${NC}"
        else
          echo -e "${GREEN}Starting installation...${NC}"
        fi
      fi
      
      if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY-RUN] Download URL: $url${NC}"
        echo -e "${BLUE}[DRY-RUN] Would run: curl -L -o /tmp/package.deb $url${NC}"
        echo -e "${BLUE}[DRY-RUN] Would run: sudo apt install -y /tmp/package.deb${NC}"
        return 0
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
      
      if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Would install $app_name (AppImage)${NC}"
        echo -e "${BLUE}[DRY-RUN] Download URL: $url${NC}"
        echo -e "${BLUE}[DRY-RUN] Package keyword: $pkg_keyword${NC}"
        echo -e "${BLUE}[DRY-RUN] Would download to /tmp/${app_name}.AppImage${NC}"
        echo -e "${BLUE}[DRY-RUN] Would integrate with gear-lever${NC}"
        echo -e "${BLUE}[DRY-RUN] Target: $HOME/AppImages/${pkg_keyword}.appimage${NC}"
        return 0
      fi
    
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
