#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Opera] Starting Kasm Single Application..."

OPERA_BIN="/usr/bin/opera"
PGREP="opera/opera"

DEFAULT_ARGS="--no-first-run --no-default-browser-check --disable-session-crashed-bubble --disable-infobars --password-store=basic"
ARGS="${APP_ARGS:-$DEFAULT_ARGS}"

URL="${KASM_URL:-${LAUNCH_URL:-}}"

CMD=("$OPERA_BIN")
read -r -a EXTRA_ARGS <<< "$ARGS" || true
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi
if [[ -n "$URL" ]]; then
  CMD+=("$URL")
fi

LAUNCHER_PID=""

kasm_startup() {
  echo "[Opera] Entering application monitoring loop..."

  while true; do
    if ! pgrep -f "$PGREP" > /dev/null; then
      if [[ -z "$LAUNCHER_PID" ]] || ! kill -0 "$LAUNCHER_PID" 2>/dev/null; then

        echo "[Opera] Opera is not running."

        /usr/bin/filter_ready
        /usr/bin/desktop_ready

        echo "[Opera] Launching Opera..."

        "${CMD[@]}" &
        LAUNCHER_PID=$!
      fi
    fi

    sleep 1
  done
}

kasm_startup