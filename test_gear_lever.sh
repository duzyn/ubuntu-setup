#!/bin/bash
# Test script for gear-lever-appimage integration
# Following TDD: Write tests first, watch them fail, then implement

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0

# Test 1: apps.json should contain gear-lever-appimage entry
test_apps_json_has_gear_lever() {
    echo "Test 1: Checking apps.json for gear-lever-appimage entry..."
    if jq -e '.[] | select(.name == "gear-lever-appimage")' apps.json >/dev/null 2>&1; then
        echo -e "${GREEN}PASS: gear-lever-appimage found in apps.json${NC}"
        return 0
    else
        echo -e "${RED}FAIL: gear-lever-appimage not found in apps.json${NC}"
        return 1
    fi
}

# Test 2: gear-lever-appimage should have correct format
test_gear_lever_format_is_appimage() {
    echo "Test 2: Checking gear-lever-appimage format is 'appimage'..."
    local format
    format=$(jq -r '.[] | select(.name == "gear-lever-appimage") | .format // empty' apps.json)
    if [ "$format" = "appimage" ]; then
        echo -e "${GREEN}PASS: gear-lever-appimage format is 'appimage'${NC}"
        return 0
    else
        echo -e "${RED}FAIL: gear-lever-appimage format is '$format' (expected 'appimage')${NC}"
        return 1
    fi
}

# Test 3: gear-lever-appimage should have correct github_repo
test_gear_lever_has_correct_repo() {
    echo "Test 3: Checking gear-lever-appimage has correct github_repo..."
    local repo
    repo=$(jq -r '.[] | select(.name == "gear-lever-appimage") | .github_repo // empty' apps.json)
    if [ "$repo" = "pkgforge-dev/Gear-Lever-AppImage" ]; then
        echo -e "${GREEN}PASS: gear-lever-appimage has correct github_repo${NC}"
        return 0
    else
        echo -e "${RED}FAIL: gear-lever-appimage github_repo is '$repo' (expected 'pkgforge-dev/Gear-Lever-AppImage')${NC}"
        return 1
    fi
}

# Test 4: 3rd.sh should not reference 'appman' (replaced by gear-lever)
test_no_appman_in_3rd_sh() {
    echo "Test 4: Checking 3rd.sh does not contain 'appman' references..."
    if grep -q "appman" 3rd.sh 2>/dev/null; then
        echo -e "${RED}FAIL: 3rd.sh still contains 'appman' references${NC}"
        return 1
    else
        echo -e "${GREEN}PASS: No 'appman' references in 3rd.sh${NC}"
        return 0
    fi
}

# Test 5: 3rd.sh should not use AppImageLauncher (replaced by gear-lever)
test_no_appimagelauncher_in_3rd_sh() {
    echo "Test 5: Checking 3rd.sh does not use AppImageLauncher..."
    if grep -q "ail-cli\|AppImageLauncher" 3rd.sh 2>/dev/null; then
        echo -e "${RED}FAIL: 3rd.sh still uses AppImageLauncher${NC}"
        return 1
    else
        echo -e "${GREEN}PASS: No AppImageLauncher references in 3rd.sh${NC}"
        return 0
    fi
}

# Test 6: 3rd.sh should have install_gear_lever function
test_install_gear_lever_function_exists() {
    echo "Test 6: Checking 3rd.sh has install_gear_lever function..."
    if grep -q "^install_gear_lever()" 3rd.sh 2>/dev/null; then
        echo -e "${GREEN}PASS: install_gear_lever function found in 3rd.sh${NC}"
        return 0
    else
        echo -e "${RED}FAIL: install_gear_lever function not found in 3rd.sh${NC}"
        return 1
    fi
}

# Test 7: 3rd.sh should use gear-lever in install_appimage function
test_install_appimage_uses_gear_lever() {
    echo "Test 7: Checking install_appimage uses gear-lever..."
    # Extract the install_appimage function and check for gear-lever usage
    if grep -A 30 "^install_appimage()" 3rd.sh | grep -q "gear-lever\|GearLever"; then
        echo -e "${GREEN}PASS: install_appimage uses gear-lever${NC}"
        return 0
    else
        echo -e "${RED}FAIL: install_appimage does not use gear-lever${NC}"
        return 1
    fi
}

# Test 8: 3rd.sh should reference gear-lever in help text
test_help_text_mentions_gear_lever() {
    echo "Test 8: Checking help text mentions gear-lever..."
    if grep -q "gear-lever" 3rd.sh 2>/dev/null; then
        echo -e "${GREEN}PASS: Help text mentions gear-lever${NC}"
        return 0
    else
        echo -e "${RED}FAIL: Help text does not mention gear-lever${NC}"
        return 1
    fi
}

# Test 9: apps.json asset_pattern should match actual GitHub releases
# This tests that our regex pattern works with real filenames like:
# Gear_Lever-4.4.8-1-anylinux-x86_64.AppImage
test_asset_pattern_matches_real_filename() {
    echo "Test 9: Checking asset_pattern matches real GitHub filename..."
    local pattern
    pattern=$(jq -r '.[] | select(.name == "gear-lever-appimage") | .asset_pattern // empty' apps.json)

    # Test with real filename format from GitHub
    local test_filename="Gear_Lever-4.4.8-1-anylinux-x86_64.AppImage"

    # Use Python to test regex since bash doesn't support full regex
    if python3 -c "import re; m = re.search(r'$pattern', '$test_filename'); print('Match:', m.group(1) if m else 'No match')" 2>/dev/null | grep -q "4.4.8-1"; then
        echo -e "${GREEN}PASS: asset_pattern correctly matches real filename${NC}"
        return 0
    else
        echo -e "${RED}FAIL: asset_pattern does not match real filename${NC}"
        echo "  Pattern: $pattern"
        echo "  Test filename: $test_filename"
        return 1
    fi
}

# Run all tests
echo "=========================================="
echo "Running gear-lever-appimage TDD tests"
echo "=========================================="
echo ""

# Test apps.json
test_apps_json_has_gear_lever || FAILED=$((FAILED + 1))
test_gear_lever_format_is_appimage || FAILED=$((FAILED + 1))
test_gear_lever_has_correct_repo || FAILED=$((FAILED + 1))
test_asset_pattern_matches_real_filename || FAILED=$((FAILED + 1))

echo ""

# Test 3rd.sh
test_no_appman_in_3rd_sh || FAILED=$((FAILED + 1))
test_no_appimagelauncher_in_3rd_sh || FAILED=$((FAILED + 1))
test_install_gear_lever_function_exists || FAILED=$((FAILED + 1))
test_install_appimage_uses_gear_lever || FAILED=$((FAILED + 1))
test_help_text_mentions_gear_lever || FAILED=$((FAILED + 1))

echo ""
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests PASSED!${NC}"
    exit 0
else
    echo -e "${RED}$FAILED test(s) FAILED${NC}"
    exit 1
fi
