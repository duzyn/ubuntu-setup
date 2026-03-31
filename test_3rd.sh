#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_UNDER_TEST="$SCRIPT_DIR/3rd.sh"
PASSED=0
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

test_cmd() {
  local name="$1"
  local cmd="$2"
  local pattern="$3"

  echo -n "Test: $name ... "

  local output
  output=$(eval "$cmd" 2>&1) || true

  if echo "$output" | grep -q "$pattern"; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
  else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
  fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Unit Tests for 3rd.sh${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Basic tests
test_cmd "Script exists" "test -f $SCRIPT_UNDER_TEST && echo ok" "ok"
test_cmd "Syntax valid" "bash -n $SCRIPT_UNDER_TEST && echo ok" "ok"

# Help command
test_cmd "help command" "bash $SCRIPT_UNDER_TEST help" "Usage:"
test_cmd "help option -h" "bash $SCRIPT_UNDER_TEST -h" "Usage:"
test_cmd "help option --help" "bash $SCRIPT_UNDER_TEST --help" "Usage:"

# List commands
test_cmd "list command" "bash $SCRIPT_UNDER_TEST list" "Available applications"
test_cmd "list --installed" "bash $SCRIPT_UNDER_TEST list --installed" "Installed applications"
test_cmd "list --outdated" "bash $SCRIPT_UNDER_TEST list --outdated" "Apps that need updates"

# Install commands with new format
test_cmd "install --deb dry-run" "bash $SCRIPT_UNDER_TEST install --deb cherry-studio --dry-run" "DRY-RUN"
test_cmd "install --appimage dry-run" "bash $SCRIPT_UNDER_TEST install --appimage aya --dry-run" "DRY-RUN"

# Error cases
test_cmd "install without type" "bash $SCRIPT_UNDER_TEST install cherry-studio 2>&1" "Must specify --deb or --appimage"
test_cmd "Unknown command" "bash $SCRIPT_UNDER_TEST unknown 2>&1" "Unknown command"
test_cmd "Non-existent app" "bash $SCRIPT_UNDER_TEST install --deb fakeapp --dry-run 2>&1" "not found"

# Config file
test_cmd "Config file exists" "test -f $SCRIPT_DIR/versions.json && echo ok" "ok"

# Upgrade command (dry-run check - it will check but not upgrade)
test_cmd "upgrade command check" "bash $SCRIPT_UNDER_TEST list --outdated" "Apps that need updates"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo -e "${BLUE}========================================${NC}"

exit $FAILED
