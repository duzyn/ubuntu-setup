#!/usr/bin/env bash
# Based on https://github.com/devstructure/ubuntu and
# https://github.com/covertsh/ubuntu-preseed-iso-generator


# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
: "${DEBUG="false"}"
[[ "$DEBUG" == "true" ]] && set -o xtrace

ISO_URL=$1
SOURCE_ISO="$(basename "$ISO_URL")"

if [[ -z $1 ]]; then
    die "ISO URL is empty."
fi

# Utilities should installed before run this script
log "Checking required utilities..."
[[ ! -x "$(command -v wget)" ]] && die "wget is not installed."
log "All required utilities are installed."

# Download ISO file
if [[ -f "$SOURCE_ISO" ]]; then
    log "Using exists $SOURCE_ISO..."
else
    log "Downloading $SOURCE_ISO..."
    wget -O "$SOURCE_ISO" "$ISO_URL"
    log "Downloaded $SOURCE_ISO."
fi

# Check SHA256SUMS
log "Verifying ISO file..."
if [[ "$(sha256sum "$SOURCE_ISO" | cut -f1 -d " ")" == "$(wget -qO- "$(dirname "$ISO_URL")/SHA256SUMS" | grep -P "$SOURCE_ISO\$" | cut -f1 -d " ")" ]]; then
    log "ISO file is verified."
    die "Completed." 0
else
    die "ISO file verification is failed, please download the file again!"
fi

