#!/usr/bin/env bash

set -Eeuo pipefail

echo "[Chrome] Starting Kasm Single Application..."

# Application configuration
START_COMMAND="/usr/bin/google-chrome"
PGREP="chrome"

# Chrome arguments
DEFAULT_ARGS="--no-first-run --no-default-browser-check --disable-session-crashed-bubble --disable-infobars --password-store=basic"

ARGS="${APP_ARGS:-$DEFAULT_ARGS}"

# Get launch URL
URL="${KASM_URL:-${LAUNCH_URL:-}}"

# Start application
kasm_startup() {
    echo "[Chrome] Entering application monitoring loop..."

    while true; do

        if ! pgrep -x "$PGREP" > /dev/null; then

            echo "[Chrome] Chrome is not running."

            /usr/bin/filter_ready
            /usr/bin/desktop_ready

            echo "[Chrome] Launching Google Chrome..."

            "$START_COMMAND" $ARGS "$URL" &

        fi

        sleep 1
    done
}

kasm_startup