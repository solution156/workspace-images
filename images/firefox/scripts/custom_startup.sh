#!/usr/bin/env bash

set -Eeuo pipefail

echo "[Firefox] Starting Kasm Single Application..."

# Application configuration
START_COMMAND="/opt/firefox/firefox"
PGREP="firefox"
PROFILE_DIR="${HOME}/.mozilla/firefox/kasm"

# Firefox arguments
DEFAULT_ARGS="--no-remote --new-instance --profile ${PROFILE_DIR}"

ARGS="${APP_ARGS:-$DEFAULT_ARGS}"

# Tách ARGS thành mảng để tránh lỗi khi có khoảng trắng
read -r -a ARGS_ARR <<< "$ARGS"

# Get launch URL
URL="${KASM_URL:-${LAUNCH_URL:-}}"

# Kiểm tra Firefox đang chạy (wrapper hoặc binary thật)
is_firefox_running() {
    pgrep -x "firefox" > /dev/null || pgrep -x "firefox-bin" > /dev/null
}

# Chuẩn bị profile trước khi mở Firefox
prepare_profile() {
    if ! mkdir -p "${PROFILE_DIR}"; then
        echo "[Firefox] ERROR: Không tạo được ${PROFILE_DIR}"
        return 1
    fi

    # Xóa lock cũ nếu Firefox từng bị crash
    rm -f "${PROFILE_DIR}/.parentlock" "${PROFILE_DIR}/lock" 2>/dev/null || true
    return 0
}

export MOZ_GTK_TITLEBAR_DECORATION=client

# Start application
kasm_startup() {
    echo "[Firefox] Entering application monitoring loop..."

    while true; do

        if ! is_firefox_running; then

            echo "[Firefox] Firefox is not running."

            /usr/bin/filter_ready
            /usr/bin/desktop_ready

            if ! prepare_profile; then
                sleep 5
                continue
            fi

            echo "[Firefox] Launching Firefox..."

            if [[ -n "$URL" ]]; then
                "$START_COMMAND" "${ARGS_ARR[@]}" "$URL" &
            else
                "$START_COMMAND" "${ARGS_ARR[@]}" &
            fi

        fi

        sleep 1
    done
}

kasm_startup