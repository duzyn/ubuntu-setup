#!/bin/bash
set -euo pipefail

# GitHub proxy (optional)
GH_PROXY="${GH_PROXY:-}"

curl -fsSL https://opencode.ai/install \
  | sed -e "s|https://github.com/anomalyco/opencode/releases/latest/download/|${GH_PROXY}&|g" \
  | bash
