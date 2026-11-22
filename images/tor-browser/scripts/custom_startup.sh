#!/usr/bin/env bash

set -Eeuo pipefail

echo "[Tor] Starting Kasm Single Application..."

# Application configuration
TOR_BIN="/opt/tor-browser/Browser/start-tor-browser"
PGREP="firefox"

# Tor Browser arguments (empty by default)
DEFAULT_ARGS=""
ARGS="${APP_ARGS:-$DEFAULT_ARGS}"

# Get launch URL
URL="${KASM_URL:-${LAUNCH_URL:-}}"

# Build command line
CMD=("$TOR_BIN")
read -r -a EXTRA_ARGS <<< "$ARGS" || true
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi
if [[ -n "$URL" ]]; then
  CMD+=("$URL")
fi

export MOZ_GTK_TITLEBAR_DECORATION=client

LAUNCHER_PID=""

kasm_startup() {
  echo "[Tor] Entering application monitoring loop..."

  while true; do

    # Relaunch only if the browser is gone AND the previous launcher has exited
    if ! pgrep -f "$PGREP" > /dev/null; then
      if [[ -z "$LAUNCHER_PID" ]] || ! kill -0 "$LAUNCHER_PID" 2>/dev/null; then

        echo "[Tor] Tor Browser is not running."

        /usr/bin/filter_ready
        /usr/bin/desktop_ready

        echo "[Tor] Launching Tor Browser..."

        "${CMD[@]}" &
        LAUNCHER_PID=$!
      fi
    fi

    sleep 1
  done
}

# --------------------------------------------------
# Tor Browser prefs: tải file về $HOME/Downloads
# --------------------------------------------------
PROFILE_DIR="/opt/tor-browser/Browser/TorBrowser/Data/Browser/profile.default"
DL_DIR="${HOME}/Downloads"

mkdir -p "${DL_DIR}" "${PROFILE_DIR}"

cat > "${PROFILE_DIR}/user.js" <<EOF
user_pref("torbrowser.settings.quickstart.enabled", true);
user_pref("browser.download.folderList", 2);
user_pref("browser.download.dir", "${DL_DIR}");
user_pref("browser.download.lastDir", "${DL_DIR}");
user_pref("browser.download.useDownloadDir", true);
user_pref("browser.download.always_ask_before_handling_new_types", false);
EOF

echo "[Tor] Download directory: ${DL_DIR}"

kasm_startup