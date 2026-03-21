#!/bin/bash
set -euo pipefail

# apt.sh - Install applications from Ubuntu apt repositories
# Usage: ./apt.sh

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# ============================================
# Define packages to install
# Format: "command:package-name:description"
# Add new apps here - they will be automatically installed
# ============================================
declare -a PACKAGES=(
  # Development tools
  "adb:adb:Android Debug Bridge"
  "scrcpy:scrcpy:Android screen mirroring"
  "apktool:apktool:APK reverse engineering"
  "jq:jq:JSON processor"
  "rg:ripgrep:Fast text search"
  
  # Multimedia
  "audacity:audacity:Audio editor"
  "vlc:vlc:Media player"
  "obs:obs-studio:Screen recording and streaming"
  "gimp:gimp:Image editor"
  "inkscape:inkscape:Vector graphics editor"
  "scrcpy:scrcpy:Screen mirroring"
  
  # Office & Productivity
  "calibre:calibre:E-book management"
  "libreoffice:libreoffice:Office suite"
  "thunderbird:thunderbird:Email client"
  "keepassxc:keepassxc:Password manager"
  "copyq:copyq:Advanced clipboard manager"
  "pandoc:pandoc:Document conversion"
  "scribus:scribus:Desktop publishing"
  
  # Graphics & Photography
  "digikam:digikam:Photo management"
  "flameshot:flameshot:Screenshot tool"
  "freecad:freecad:Open source CAD"
  "pdfarranger:pdfarranger:PDF manipulation"
  
  # System & Utilities
  "filezilla:filezilla:FTP client"
  "plank:plank:Dock application"
  "gs:ghostscript:PostScript and PDF processing"
  
  # Fonts
  "fc-list:fonts-noto-cjk:Noto CJK fonts (Chinese support)"
  "fc-list:fonts-firacode:Fira Code programming font"
  
  # Icons
  "true:papirus-icon-theme:Papirus icon theme"
)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installing apt packages${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run as root (use sudo)${NC}"
  exit 1
fi

# Update package list
echo -e "\n${GREEN}Updating package list...${NC}"
sudo apt update

# Install packages
declare -a INSTALL_LIST=()
declare -a SKIPPED_LIST=()

for entry in "${PACKAGES[@]}"; do
  IFS=':' read -r cmd pkg desc <<< "$entry"
  
  # Special handling for fonts and icons (check differently)
  if [[ "$pkg" == fonts-* ]] || [[ "$pkg" == *-icon-* ]]; then
    if dpkg -l "$pkg" &>/dev/null; then
      echo -e "${YELLOW}✓ $desc ($pkg) already installed${NC}"
      SKIPPED_LIST+=("$desc")
    else
      echo -e "${GREEN}→ Will install $desc ($pkg)${NC}"
      INSTALL_LIST+=("$pkg")
    fi
  else
    # Standard command check
    if command -v "$cmd" &>/dev/null; then
      echo -e "${YELLOW}✓ $desc ($pkg) already installed${NC}"
      SKIPPED_LIST+=("$desc")
    else
      echo -e "${GREEN}→ Will install $desc ($pkg)${NC}"
      INSTALL_LIST+=("$pkg")
    fi
  fi
done

# Install all packages in one command if any need installation
if [ ${#INSTALL_LIST[@]} -eq 0 ]; then
  echo -e "\n${GREEN}========================================${NC}"
  echo -e "${GREEN}All packages already installed!${NC}"
  echo -e "${GREEN}========================================${NC}"
else
  echo -e "\n${GREEN}========================================${NC}"
  echo -e "${GREEN}Installing ${#INSTALL_LIST[@]} packages...${NC}"
  echo -e "${GREEN}========================================${NC}"
  
  if sudo apt install -y "${INSTALL_LIST[@]}"; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Successfully installed:${NC}"
    printf '  - %s\n' "${INSTALL_LIST[@]}"
    echo -e "${GREEN}========================================${NC}"
  else
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}✗ Failed to install some packages${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
  fi
fi

# Summary
echo -e "\n${GREEN}Summary:${NC}"
echo -e "  ${GREEN}Installed:${NC} ${#INSTALL_LIST[@]}"
echo -e "  ${YELLOW}Already present:${NC} ${#SKIPPED_LIST[@]}"
echo -e "  ${GREEN}Total:${NC} ${#PACKAGES[@]}"

exit 0
