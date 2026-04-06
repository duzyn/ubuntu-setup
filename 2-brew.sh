#!/bin/bash
set -e

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

git_clone_with_retry() {
  local repo_url=$1
  local target_dir=$2
  local max_attempts=3
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt/$max_attempts: Cloning from $repo_url"
    
    if [ -d "$target_dir" ]; then
      rm -rf "$target_dir"
    fi
    
    if git clone --depth 1 --single-branch --branch master "$repo_url" "$target_dir" 2>&1; then
      echo "Clone successful"
      return 0
    fi
    
    echo "Clone failed, waiting before retry..."
    sleep 5
    attempt=$((attempt + 1))
  done
  
  return 1
}

if command -v brew &>/dev/null; then
  echo "Homebrew is already installed: $(brew --version | head -1)"
else
  echo "Installing Homebrew..."
  
  sudo apt-get update
  sudo apt-get install -y build-essential procps curl file git
  
  if [ -d "$BREW_PREFIX" ]; then
    echo "Removing existing Homebrew directory..."
    sudo rm -rf "$BREW_PREFIX"
  fi
  
  sudo mkdir -p "$BREW_PREFIX"
  sudo chown -R "$(whoami):$(whoami)" "$BREW_PREFIX"
  
  git config --global http.postBuffer 524288000
  git config --global http.lowSpeedLimit 0
  git config --global http.lowSpeedTime 999999
  
  HOMEBREW_BREW_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/brew.git"
  
  if ! git_clone_with_retry "$HOMEBREW_BREW_GIT_REMOTE" "$BREW_PREFIX/Homebrew"; then
    echo "NJU mirror failed, trying official GitHub mirror..."
    HOMEBREW_BREW_GIT_REMOTE="https://github.com/Homebrew/brew.git"
    if ! git_clone_with_retry "$HOMEBREW_BREW_GIT_REMOTE" "$BREW_PREFIX/Homebrew"; then
      echo "Error: Failed to clone Homebrew from all mirrors"
      exit 1
    fi
  fi
  
  mkdir -p "$BREW_PREFIX/bin"
  ln -sf "$BREW_PREFIX/Homebrew/bin/brew" "$BREW_PREFIX/bin/brew"
  
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  
  export HOMEBREW_NO_AUTO_UPDATE=1
  
  echo "Homebrew installation completed"
fi

echo "Configuring NJU mirror for Homebrew..."

BREW_SHELLENV_INIT="\n# Homebrew initialization\neval \"\$($BREW_PREFIX/bin/brew shellenv)\""

BREW_MIRROR_CONFIG='\n# Homebrew NJU mirror configuration\nexport HOMEBREW_INSTALL_FROM_API=1\nexport HOMEBREW_BREW_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/brew.git"\nexport HOMEBREW_CORE_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git"\nexport HOMEBREW_BOTTLE_DOMAIN="https://mirrors.nju.edu.cn/homebrew-bottles"'

if ! grep -q "brew shellenv" "$HOME/.bashrc"; then
  echo "Adding Homebrew initialization to ~/.bashrc..."
  echo -e "$BREW_SHELLENV_INIT" >> "$HOME/.bashrc"
else
  echo "Homebrew initialization already exists in ~/.bashrc"
fi

if ! grep -q "HOMEBREW_BREW_GIT_REMOTE.*mirror.nju.edu.cn" "$HOME/.bashrc"; then
  echo "Adding NJU mirror configuration to ~/.bashrc..."
  echo -e "$BREW_MIRROR_CONFIG" >> "$HOME/.bashrc"
else
  echo "NJU mirror configuration already exists in ~/.bashrc"
fi

export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_BREW_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirror.nju.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.nju.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirror.nju.edu.cn/homebrew-bottles/api"

if [ -f "$BREW_PREFIX/bin/brew" ]; then
  eval "$("$BREW_PREFIX/bin/brew" shellenv)"
fi

echo "Testing Homebrew..."
if brew --version; then
  echo "Homebrew is working correctly"
else
  echo "Error: Homebrew test failed"
  exit 1
fi

echo ""
echo "Installing Starship via Homebrew..."
if brew install starship; then
  echo "Starship installed successfully"
  
  STARSHIP_INIT='\n# Starship prompt initialization\neval "$(starship init bash)"'
  if ! grep -q "starship init bash" "$HOME/.bashrc"; then
    echo "Adding Starship initialization to ~/.bashrc..."
    echo -e "$STARSHIP_INIT" >> "$HOME/.bashrc"
  else
    echo "Starship initialization already exists in ~/.bashrc"
  fi
else
  echo "Warning: Failed to install Starship"
fi

echo ""
echo "Homebrew with NJU mirror configuration completed"
echo ""
echo "Next steps:"
echo "  Run 'source ~/.bashrc' to reload shell configuration"
echo "  Run 'brew -v' to verify installation"
echo ""
echo "To install packages:"
echo "  brew install <package-name>"
