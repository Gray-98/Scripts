#!/usr/bin/env bash
# Wrapper to run the Expect script. Ensures `expect` is installed on Debian/Ubuntu.

set -eu
# Enable `pipefail` only when running under Bash to avoid errors in shells
# that don't support this option (for example, if someone runs the script with
# `sh run_hj.sh` or from zsh). If Bash is present, enable pipefail for safer
# pipe handling.
if [ -n "${BASH_VERSION-}" ]; then
    set -o pipefail
fi

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECT_SCRIPT="$THIS_DIR/run_hj.expect"

log() { printf "%s\n" "$*" >&2; }

if ! command -v expect >/dev/null 2>&1; then
    log "Expect is not installed. Installing (requires sudo)..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y expect
    else
        log "No apt-get available. Please install 'expect' manually and re-run."
        exit 1
    fi
fi

if [ ! -x "$EXPECT_SCRIPT" ]; then
    # Ensure the expect script is executable
    chmod +x "$EXPECT_SCRIPT" || true
fi

log "Starting automated run: invoking expect script $EXPECT_SCRIPT"
"$EXPECT_SCRIPT"
EXIT_CODE=$?
log "Expect script exited with code $EXIT_CODE"
exit $EXIT_CODE
