#!/bin/bash
set -euo pipefail

curl -fsSL https://opencode.ai/install \
  | sed -e 's|https://github.com/anomalyco/opencode/releases/latest/download/|https://gh-proxy.com/&|g' \
  | bash
