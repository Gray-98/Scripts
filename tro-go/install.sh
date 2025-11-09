#!/usr/bin/env bash
# One-step installer: after cloning the repo, run ./install.sh to install dependencies,
# copy scripts to /usr/local/bin, install systemd unit & timer, and enable the timer.

set -eu
# Enable `pipefail` when running under Bash. Some shells (or when invoked via
# `sh`/`zsh`) don't support the `-o pipefail` option and will error with
# "Illegal option -o pipefail". Check for Bash and enable it only there.
if [ -n "${BASH_VERSION-}" ]; then
    set -o pipefail
fi

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
DEPLOY_DIR="$ROOT_DIR/deploy"

need_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "This script needs root. Re-running with sudo..."
        exec sudo bash "$0" "$@"
    fi
}

main() {
    need_root

    echo "Starting one-step install from repo: $ROOT_DIR"

    # Check for systemd
    if ! command -v systemctl >/dev/null 2>&1; then
        echo "systemd not found on this system. Aborting."
        exit 1
    fi

    # Ensure apt-get exists (Debian/Ubuntu)
    if ! command -v apt-get >/dev/null 2>&1; then
        echo "apt-get not found. This installer expects a Debian-based system. Aborting."
        exit 1
    fi

    echo "Installing expect (if needed)"
    apt-get update -y
    apt-get install -y expect || true

    echo "Copying scripts to /usr/local/bin"
    install -m 0755 "$SCRIPTS_DIR/run_hj.sh" /usr/local/bin/run_hj.sh
    install -m 0755 "$SCRIPTS_DIR/run_hj.expect" /usr/local/bin/run_hj.expect

    echo "Installing systemd unit and timer"
    cp "$DEPLOY_DIR/run-hj.service" /etc/systemd/system/run-hj.service
    cp "$DEPLOY_DIR/run-hj.timer" /etc/systemd/system/run-hj.timer

    echo "Reloading systemd"
    systemctl daemon-reload

    echo "Running one immediate installation run to establish the schedule"
    # Run the oneshot service once now. If it succeeds, enable the timer so
    # OnUnitActiveSec=5d will schedule the next run 5 days after this successful run.
    if systemctl start run-hj.service; then
        echo "Initial run succeeded — enabling and starting timer"
        systemctl enable --now run-hj.timer
    else
        echo "Initial run failed. Not enabling timer. Check the service status with: systemctl status run-hj.service"
        exit 1
    fi

    echo "Installation finished. Check timer status with: systemctl status run-hj.timer"
    echo "You can also test a run manually: /usr/local/bin/run_hj.sh"
}

main "$@"
