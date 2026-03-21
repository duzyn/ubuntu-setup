#!/bin/bash
set -e

# Install opencode if not present
if ! command -v opencode &>/dev/null; then
  echo "Installing opencode..."
  npm install -g opencode-ai
fi

# oh-my-opencode installation
if ! command -v oh-my-opencode &>/dev/null; then
  echo "Installing oh-my-opencode..."
  npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no --openai=no --opencode-zen=no --zai-coding-plan=no || true
fi
