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
