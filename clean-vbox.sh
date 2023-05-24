#!/usr/bin/env bash
# Inspired by https://github.com/devstructure/ubuntu

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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
. "$SCRIPT_DIR/config.sh"
BUILT_ISO="$SCRIPT_DIR/${SOURCE_ISO%.*}-custom.iso"


[[ ! -x "$(command -v date)" ]] && echo "date command not found." && exit 1

function log() {
    echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

function die() {
    local msg=$1
    local code=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
    log "$msg"
    exit "$code"
}



# $BUILT_ISO is Linux Path, doesn't work on Windows, so use releative path instead.
cd "$SCRIPT_DIR"

if [[ "$("$VBOXMANAGE_CMD" list vms)" =~ $VBOX_NAME ]]; then
    if [[ "$("$VBOXMANAGE_CMD" list runningvms)" =~ $VBOX_NAME ]]; then
        log "Power off $VBOX_NAME."
        "$VBOXMANAGE_CMD" controlvm "$VBOX_NAME" poweroff
    fi

    until "$VBOXMANAGE_CMD" showvminfo "$VBOX_NAME" | grep "^State: *powered off"
    do
        sleep 1
    done

    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" --name "IDE" --remove || true
    "$VBOXMANAGE_CMD" storagectl "$VBOX_NAME" --name "SATA" --remove || true
    "$VBOXMANAGE_CMD" unregistervm "$VBOX_NAME" || true
    "$VBOXMANAGE_CMD" closemedium dvd "$(basename "$BUILT_ISO")" || true
    "$VBOXMANAGE_CMD" closemedium disk "$VBOX_NAME/$VBOX_NAME.${VBOX_HDD_FORMAT,,}" || true
    rm -rf "$VBOX_NAME"

else
    log "There is no virtual machine to clean."
fi

if [[ -d "$VBOX_SETTING_DIR/$VBOX_NAME" ]]; then
    log "Cleaning setting dir..."
    rm -rf "${VBOX_SETTING_DIR:?}/$VBOX_NAME"
else
    log "There is no virtual machine setting files to clean."
fi

die "Completed!" 0
