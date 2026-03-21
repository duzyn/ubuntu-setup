# Agent Instructions for ubuntu-setup

**Generated:** 2026-03-22 06:02:40  
**Commit:** f573f2e  
**Branch:** main

This repository contains automated setup scripts for Ubuntu/Linux Mint systems, with a focus on Chinese users (Aliyun mirrors, Chinese input methods).

## Project Structure

- **Shell scripts**: `0-*.sh` to `9-*.sh` - Sequential setup scripts (numbered for ordering)
- **Python**: `update_versions.py` - Version tracking utility
- **JSON**: `apps.json` - App metadata; `versions.json` - Current versions
- **GitHub Actions**: `.github/workflows/` - Automated version checking
- **Entry Point**: No central orchestrator - scripts must be run manually in sequence

## Execution Model

**No unified entry point.** Each script is standalone and must be run manually:

```bash
# 1. Generate versions.json first
export GITHUB_TOKEN=<token>  # Optional, for API rate limits
python3 update_versions.py apps.json

# 2. Run setup scripts in sequence (most require sudo)
bash 0-chinese.sh      # First: Aliyun mirrors, Chinese input
bash 1-apt.sh         # Second: APT packages (sudo required)
bash 3rd.sh            # Third: Third-party apps from versions.json
bash 4-nodejs.sh       # Fourth: Node.js via nvm
bash 9-optional.sh     # Fifth: Optional packages (sudo required)
```

**Note:** `setup.sh` is NOT a main runner - it only configures plank dock autostart.

## Build/Test Commands

### Shell Scripts
```bash
# Validate bash syntax
bash -n <script>.sh

# Run a specific script (use with caution - modifies system)
bash <script>.sh

# Test JSON validity
python3 -m json.tool apps.json > /dev/null && echo "Valid JSON"

# Run gear-lever test
bash test_gear_lever.sh
```

### Python
```bash
# Run version checker (requires GITHUB_TOKEN for API access)
export GITHUB_TOKEN=<token>
python3 update_versions.py apps.json

# Python syntax check
python3 -m py_compile update_versions.py
```

### Git Workflow
```bash
# Always pull before committing
git pull --rebase

# Stage changes
git add <files>

# Commit with descriptive messages
git commit -m "<type>: <description>"

# Push to remote
git push
```

## Code Style Guidelines

### Shell Scripts

**Shebang and Safety:**
```bash
#!/bin/bash
set -e                    # Exit on error
set -euo pipefail        # Stricter mode (use where appropriate)
```

**Variable Naming:**
- `UPPER_CASE` - Constants and environment variables
- `lower_case` - Local variables
- `${VAR}` - Always quote variables: `"${VAR}"`

**Functions:**
```bash
# Use snake_case
function_name() {
    local var="value"    # Use local for function variables
    # ...
}
```

**GitHub/Mirror URLs:**
- ALWAYS use `${GH_PROXY}` prefix for GitHub URLs
- Format: `${GH_PROXY}https://github.com/...`
- Supports users in China with restricted GitHub access

**Output:**
- Use color codes consistently: `RED='\033[0;31m'`, `GREEN='\033[0;32m'`, `NC='\033[0m'`
- Informative echo statements for each operation
- Error messages to stderr: `echo "Error" >&2`
- **All scripts and output messages must be in English, no Chinese characters allowed**

### Python (update_versions.py)

**Type Hints:**
```python
from typing import Dict, Optional, Tuple

def func() -> Optional[str]:
    pass
```

**Function Structure:**
- Single responsibility functions
- English print statements only (no Chinese characters)
- Comprehensive try/except error handling

**Environment Variables:**
- `GITHUB_TOKEN` - GitHub API authentication
- `GH_PROXY` - Proxy prefix for GitHub URLs

### JSON (apps.json)

**Schema Structure:**
```json
{
  "name": "app-name",
  "package_keyword": "dpkg-name",
  "format": "deb|appimage",
  "github_repo": "owner/repo",
  "asset_pattern": "regex-pattern",
  "version_extract": "github_release|apt_repo|page|filename"
}
```

**Version Extraction Methods:**
- `github_release` - Use GitHub API
- `apt_repo` - Parse APT Packages.gz
- `page` - Scrape webpage
- `filename` - Extract from download URL

## Error Handling

### Shell
- Always check command results: `if command ...; then ... fi`
- Cleanup temporary files in trap or finally blocks
- Validate inputs before use

### Python
- Use try/except for all network operations
- Return `None` for failures, never crash
- Print errors in English (no Chinese characters)

## Commit Message Format

```
<type>: <subject>

<body>

- bullet points for details
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`

## CI/CD Configuration

**Workflow:** `.github/workflows/check_versions.yml`
- Runs hourly (`0 * * * *`) - checks for updated package versions
- Auto-commits changes to `versions.json` if detected
- Uses `ubuntu-24.04` runner (non-standard - consider `ubuntu-latest`)
- Requires `secrets.GITHUB_TOKEN` for API access

## Known Issues / Deviation Warnings

⚠️ **The following files deviate from documented conventions:**

1. **Shell error handling inconsistency** - These scripts use `set -e` only (missing `u` and `pipefail`):
   - `0-chinese.sh`
   - `4-nodejs.sh`
   - `setup.sh`
   - `grub2-theme.sh`

2. **Python Chinese characters** - `update_versions.py` contains Chinese text in error messages (violates English-only rule)

3. **Non-standard script names** - These don't follow `N-*.sh` pattern:
   - `3rd.sh` (should be `2-*.sh` or `3-*.sh`?)
   - `grub2-theme.sh`
   - `test_gear_lever.sh`

4. **Incorrect header comment** - `9-optional.sh` header says "apt.sh" and "Usage: sudo ./1-apt.sh" (copy-paste error)

## Important Notes

1. **OS Target**: Linux Mint 22+ only (Ubuntu Noble/24.04 base)
2. **Mirrors**: Use Aliyun (Aliyun) for packages, SJTU for Flathub
3. **Proxy**: All GitHub URLs MUST use `${GH_PROXY}` environment variable
4. **Version Files**: Don't manually edit `versions.json` - it's auto-generated
5. **Script Ordering**: Number prefix (`0-`, `1-`, etc.) indicates execution order
6. **Missing Files**: `setup.sh` references removed files - update if modifying

## Testing Changes

1. Syntax check scripts before committing
2. Validate JSON files
3. Test Python script with `GITHUB_TOKEN` if modifying version logic
4. Check GitHub Actions workflows still valid after file moves
