# Agent Instructions for `ubuntu-setup`

This repository contains Bash scripts to automate the setup of Ubuntu 24.04 (Noble). Agents should follow these instructions to maintain consistency and reliability.

## 1. Development & Verification Commands

### Syntax Validation
Before committing any script, check for syntax errors:
- `bash -n <script_path>`

### Linting
We recommend `shellcheck` for all scripts.
- **Run on all scripts:** `shellcheck **/*.sh`
- **Install Shellcheck:** `sudo apt install shellcheck`

### Testing
There is no formal test framework. To verify a single script:
1. Use a clean Ubuntu 24.04 environment (e.g., Docker or VM).
2. Execute the script directly: `sudo bash <script_path>`
3. Verify the installation: `command -v <app_name>` or check relevant config files/versions.

## 2. Code Style Guidelines

### General
- **Shell**: Always use `#!/bin/bash`.
- **Error Handling**: Every script must start with `set -e` to exit on any command failure.
- **Indentation**: Use 2 spaces for indentation.
- **Quoting**: Always quote variables (e.g., `"$VARIABLE"`) to prevent word splitting and globbing issues.
- **Comments**: Keep comments concise; focus on "why" for non-obvious logic.

### Modularity & Integration
- Scripts in `terminal/` and `desktop/` are designed to be **sourced** by `terminal.sh` or `desktop.sh`.
- **IMPORTANT**: Avoid using `exit` in modular scripts as it will terminate the parent shell. Use `return` or conditional logic instead.

### Idempotency
Scripts must be safe to run multiple times without unintended side effects.
- Check if an application is already installed before downloading/installing:
  ```bash
  if command -v <app> &>/dev/null; then
    return 0 
  fi
  ```
- Use checks before appending to system configuration files (e.g., `/etc/environment`).

### Naming Conventions
- **App installers**: `app-<name>.sh` (e.g., `app-vscode.sh`).
- **Grouped installers**: `apps-<category>.sh` (e.g., `apps-terminal.sh`).

### Resource Management
- Always clean up temporary downloads (e.g., in `/tmp`) after installation.
- Use `sudo` explicitly for commands requiring root privileges.

## 3. Cursor & Copilot Rules
No project-specific `.cursorrules` or `.github/copilot-instructions.md` detected. Follow the guidelines above.

## 4. Installation Script Standards

This section defines the standard approach for writing application installation scripts.

### 4.1 Package Source Priority

Follow this priority order when choosing installation methods:

| Priority | Method | Use Case |
|----------|--------|----------|
| 0 | apt  | Use at first |
| 1 | homebrew  | Use when no apt is available |
| 2 | Download `.deb` from GitHub releases | Preferred for all apps with GitHub-hosted deb packages |
| 3 | AppImage + Gear Lever | For apps without deb packages (Joplin, LosslessCut, etc.) |
| 4 | flatpak | Only when no other option exists |
| Avoid | snap | Generally avoided unless no alternative |
| Avoid | Official install scripts | Avoid curl \| bash style installers |
| Avoid | PPA | PPA is slow to download |

**Rationale**: GitHub deb packages provide direct control over versions and avoid the overhead of snap/flatpak runtimes.

### 4.2 GitHub Downloads

Always use the `gh-proxy.com` proxy for GitHub URLs to improve download reliability:

```bash
# Correct format
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/USER/REPO/releases/download/v${VERSION}/app_${VERSION}_amd64.deb"

# Example
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.3/obsidian_1.5.3_amd64.deb"
```

### 4.3 Version Detection

**IMPORTANT**: Do NOT use the GitHub API for version detection. API calls are rate-limited and will fail in automated environments.

Use webpage scraping instead:

```bash
# Standard method for getting latest version
VERSION=$(curl -sI "https://github.com/USER/REPO/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

# If the tag format is different (no 'v' prefix), adjust accordingly:
VERSION=$(curl -sI "https://github.com/USER/REPO/releases/latest" | grep -i "location:" | grep -oP 'tag/\K[^\s]+' | tr -d '\r')

# Fallback: Hardcode version if scraping fails
if [[ -z "$VERSION" ]]; then
  VERSION="1.5.3"  # Current known version as fallback
fi
```

### 4.4 Status Messages

All status messages must be in English and follow these standardized formats:

| Situation | Message Format |
|-----------|----------------|
| Already installed | `[App] is already installed, skipping...` |
| Starting install | `Installing [App]...` |
| Fetching version | `Fetching latest version...` |
| Version found | `Latest version: ${VERSION}` |
| Starting download | `Downloading [App] version ${VERSION}...` |
| Download complete | `Download completed` |
| Installing package | `Installing [App]...` |
| Success | `[App] installation completed` |
| Failure | `Error: Failed to download/install [App]` |

**Example usage:**
```bash
echo "Installing VSCode..."
echo "Fetching latest version..."
VERSION=$(curl -sI "https://github.com/VSCodium/vscodium/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')
echo "Latest version: ${VERSION}"
echo "Downloading VSCode version ${VERSION}..."
```

### 4.5 AppImage Integration with Gear Lever

For applications that only provide AppImage releases (e.g., Joplin, LosslessCut), use Gear Lever for system integration:

**Step 1: Install Gear Lever**
```bash
flatpak install -y flathub it.mijorus.gearlever
```

**Step 2: Download AppImage**
```bash
APPIMAGE_PATH="$HOME/Applications/app-name.AppImage"
mkdir -p "$HOME/Applications"
curl -L "https://gh-proxy.com/https://github.com/USER/REPO/releases/download/v${VERSION}/App.AppImage" -o "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"
```

**Step 3: Integrate with Gear Lever**
```bash
flatpak run it.mijorus.gearlever "$APPIMAGE_PATH" --no-gui
```

**Complete AppImage installation example:**
```bash
#!/bin/bash
set -e

APP_NAME="joplin"
APPIMAGE_PATH="$HOME/Applications/${APP_NAME}.AppImage"

# Check if already installed
if [[ -f "$APPIMAGE_PATH" ]]; then
  echo "Joplin is already installed, skipping..."
  return 0
fi

echo "Installing Joplin..."
echo "Fetching latest version..."

VERSION=$(curl -sI "https://github.com/laurent22/joplin/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [[ -z "$VERSION" ]]; then
  VERSION="3.0.15"
fi

echo "Latest version: ${VERSION}"
echo "Downloading Joplin version ${VERSION}..."

mkdir -p "$HOME/Applications"
curl -L "https://gh-proxy.com/https://github.com/laurent22/joplin/releases/download/v${VERSION}/Joplin-${VERSION}.AppImage" -o "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

echo "Integrating with Gear Lever..."
flatpak run it.mijorus.gearlever "$APPIMAGE_PATH" --no-gui

echo "Joplin installation completed"
```

### 4.6 Error Handling

Follow these error handling practices:

1. **Return instead of exit**: Modular scripts must use `return 1` for errors, never `exit`
2. **No automatic fallback**: If deb download fails, report the error—do not automatically fall back to flatpak
3. **Cleanup on failure**: Remove temporary files even if installation fails
4. **Informative messages**: Provide clear error messages indicating what failed

```bash
# Proper error handling pattern
TEMP_FILE="/tmp/app.deb"

if ! curl -L "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
  echo "Error: Failed to download [App]"
  rm -f "$TEMP_FILE"
  return 1
fi

if ! sudo dpkg -i "$TEMP_FILE"; then
  echo "Error: Failed to install [App]"
  rm -f "$TEMP_FILE"
  return 1
fi

rm -f "$TEMP_FILE"
```

### 4.7 Script Template

Use this template as the standard structure for all installation scripts:

```bash
#!/bin/bash
# App installation script: [App Name]
# Description: [Brief description of the application]

set -e

# Configuration
APP_NAME="[app-name]"
REPO_OWNER="[owner]"
REPO_NAME="[repo]"
DEB_FILE_PREFIX="[prefix]"  # e.g., "app" for app_1.0.0_amd64.deb

# Check if already installed
if command -v "$APP_NAME" &>/dev/null; then
  echo "[App Name] is already installed, skipping..."
  return 0
fi

echo "Installing [App Name]..."
echo "Fetching latest version..."

# Get latest version via webpage scraping (NOT API)
VERSION=$(curl -sI "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

# Fallback to hardcoded version if scraping fails
if [[ -z "$VERSION" ]]; then
  VERSION="1.0.0"  # Update this periodically
  echo "Warning: Could not fetch latest version, using fallback: ${VERSION}"
else
  echo "Latest version: ${VERSION}"
fi

# Construct download URL with gh-proxy
DOWNLOAD_URL="https://gh-proxy.com/https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${VERSION}/${DEB_FILE_PREFIX}_${VERSION}_amd64.deb"

# Download
TEMP_FILE="/tmp/${APP_NAME}_${VERSION}.deb"
echo "Downloading [App Name] version ${VERSION}..."

if ! curl -L "$DOWNLOAD_URL" -o "$TEMP_FILE"; then
  echo "Error: Failed to download [App Name]"
  return 1
fi

echo "Download completed"

# Install
echo "Installing [App Name]..."

if ! sudo dpkg -i "$TEMP_FILE"; then
  echo "Error: Failed to install [App Name]"
  rm -f "$TEMP_FILE"
  return 1
fi

# Fix missing dependencies if any
sudo apt-get install -f -y

# Cleanup
rm -f "$TEMP_FILE"

echo "[App Name] installation completed"
```

### 4.8 Quick Reference Examples

**GitHub .deb installation:**
```bash
#!/bin/bash
set -e

APP_NAME="code"

if command -v "$APP_NAME" &>/dev/null; then
  echo "VSCode is already installed, skipping..."
  return 0
fi

echo "Installing VSCode..."
VERSION=$(curl -sI "https://github.com/VSCodium/vscodium/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')
echo "Latest version: ${VERSION}"

curl -L "https://gh-proxy.com/https://github.com/VSCodium/vscodium/releases/download/v${VERSION}/codium_${VERSION}_amd64.deb" -o /tmp/vscode.deb
sudo dpkg -i /tmp/vscode.deb || sudo apt-get install -f -y
rm -f /tmp/vscode.deb

echo "VSCode installation completed"
```

**apt/PPA installation:**
```bash
#!/bin/bash
set -e

APP_NAME="git"

if command -v "$APP_NAME" &>/dev/null; then
  echo "Git is already installed, skipping..."
  return 0
fi

echo "Installing Git..."
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y git
echo "Git installation completed"
```

**AppImage + Gear Lever installation:**
```bash
#!/bin/bash
set -e

APP_NAME="losslesscut"
APPIMAGE_PATH="$HOME/Applications/${APP_NAME}.AppImage"

if [[ -f "$APPIMAGE_PATH" ]]; then
  echo "LosslessCut is already installed, skipping..."
  return 0
fi

echo "Installing LosslessCut..."
VERSION=$(curl -sI "https://github.com/mifi/lossless-cut/releases/latest" | grep -i "location:" | grep -oP 'tag/v\K[^\s]+' | tr -d '\r')

if [[ -z "$VERSION" ]]; then
  VERSION="3.60.0"
fi

echo "Latest version: ${VERSION}"
mkdir -p "$HOME/Applications"
curl -L "https://gh-proxy.com/https://github.com/mifi/lossless-cut/releases/download/v${VERSION}/LosslessCut-linux-x64.AppImage" -o "$APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

flatpak run it.mijorus.gearlever "$APPIMAGE_PATH" --no-gui
echo "LosslessCut installation completed"
```
