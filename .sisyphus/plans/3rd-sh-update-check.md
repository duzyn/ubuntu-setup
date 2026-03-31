# Plan: 3rd.sh Update Check Functionality

## TL;DR
Modify `3rd.sh` to check ALL apps in `versions.json` for updates when run without arguments, with `--install <app>` for specific installs.

## Status: IMPLEMENTATION COMPLETE - Bug Fix Needed

### BUG FOUND: SIGPIPE with pipefail

**Problem**: With `set -o pipefail`, the pipeline `dpkg-query | grep -q` fails because grep exits early after finding a match, causing dpkg-query to receive SIGPIPE (exit 141). With pipefail, the pipeline returns failure.

**Fix Required in 3 locations:**

1. **Line 133** (`check_deb_update()`):
   ```bash
   # OLD (broken with pipefail):
   if dpkg-query -W -f='${Package}\n' "$pkg_keyword" 2>/dev/null; then
   # NEW (works correctly):
   if dpkg-query -W "$pkg_keyword" &>/dev/null; then
   ```

2. **Line 306** (`list_apps()`):
   ```bash
   # OLD (broken with pipefail):
   if dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -qx "$pkg_keyword"; then
   # NEW (works correctly):
   if dpkg-query -W "$pkg_keyword" &>/dev/null; then
   ```

3. **Line 458** (`install_deb()`):
   ```bash
   # OLD (broken with pipefail):
   if dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -qx "$pkg_keyword"; then
   # NEW (works correctly):
   if dpkg-query -W "$pkg_keyword" &>/dev/null; then
   ```

## TODOs

- [x] 1. Rewrite 3rd.sh with new functionality
- [ ] 2. Fix SIGPIPE bug in dpkg-query checks (3 locations)
- [ ] 3. Test the script
