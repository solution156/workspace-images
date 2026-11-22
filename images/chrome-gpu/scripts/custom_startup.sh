#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Chrome] Starting Kasm Single Application..."

START_COMMAND="/usr/bin/google-chrome"
PGREP="chrome"

# DEFAULT_ARGS="\
# --no-first-run \
# --no-default-browser-check \
# --disable-session-crashed-bubble \
# --disable-infobars \
# --password-store=basic \
# --ignore-gpu-blocklist \
# --disable-gpu-driver-bug-workaround \
# --use-gl=angle \
# --use-angle=vulkan \
# --enable-features=VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinux,AcceleratedVideoDecodeLinuxGL,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE \
# "


DEFAULT_ARGS="--no-first-run --no-default-browser-check --disable-session-crashed-bubble --disable-infobars --password-store=basic --ignore-gpu-blocklist --use-gl=egl --enable-features=VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,AcceleratedVideoDecodeLinuxGL"



export LIBVA_DRIVER_NAME=nvidia
export NVD_BACKEND=egl
export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

ARGS="${APP_ARGS:-$DEFAULT_ARGS}"
URL="${KASM_URL:-${LAUNCH_URL:-}}"

LAUNCHER=""
if [[ -n "${DRINODE:-}" && -n "${KASM_EGL_CARD:-}" ]] && command -v vglrun >/dev/null; then
    LAUNCHER="vglrun -d ${KASM_EGL_CARD}"
    echo "[Chrome] GPU mode: ${LAUNCHER}"
else
    echo "[Chrome] GPU launcher not enabled"
fi

kasm_startup() {
    echo "[Chrome] Entering application monitoring loop..."

    while true; do
        if ! pgrep -x "$PGREP" >/dev/null; then
            echo "[Chrome] Chrome is not running."

            /usr/bin/filter_ready
            /usr/bin/desktop_ready

            echo "[Chrome] Launching Google Chrome..."
            $LAUNCHER "$START_COMMAND" $ARGS "$URL" &
        fi

        sleep 1
    done
}

kasm_startup