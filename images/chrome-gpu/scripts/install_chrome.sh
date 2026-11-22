#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Chrome] Installing Google Chrome Stable..."

export DEBIAN_FRONTEND=noninteractive

# Validate architecture
ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
    echo "[Chrome] Unsupported architecture: ${ARCH}"
    exit 1
fi

# Install dependencies
apt-get update

apt-get install -y --no-install-recommends \
    ca-certificates \
    curl

# Download Chrome
CHROME_DEB="/tmp/google-chrome-stable.deb"

curl -fSL --retry 3 \
    "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
    -o "${CHROME_DEB}"

# Install Chrome
apt-get install -y --no-install-recommends "${CHROME_DEB}"

# --------------------------------------------------
# Security updates
# --------------------------------------------------

echo "[Security] Updating vulnerable packages..."

apt-get update

apt-get install -y --only-upgrade \
    apt \
    libapt-pkg6.0t64 \
    libbrotli1

echo "[Security] Security updates completed."

apt-get install -y --no-install-recommends \
    libglvnd0 libegl1 libgl1 libgles2 libglx0 \
    libvulkan1 vulkan-tools mesa-utils libxcb-dri3-0

apt-get install -y --no-install-recommends \
    git \
    vainfo

# Build NVIDIA VA-API driver from upstream
git clone \
    --depth 1 \
    --branch v0.0.18 \
    https://github.com/elFarto/nvidia-vaapi-driver.git \
    /tmp/nvidia-vaapi-driver

cd /tmp/nvidia-vaapi-driver

./install.sh --deps --clean

cd /

rm -rf /tmp/nvidia-vaapi-driver

# --------------------------------------------------
# Desktop launcher
# --------------------------------------------------

DESKTOP_DIR="${HOME}/Desktop"
APP_DESKTOP="/usr/share/applications/google-chrome.desktop"

mkdir -p "${DESKTOP_DIR}"

if [[ ! -f "${APP_DESKTOP}" ]]; then
    echo "[Chrome] ERROR: Chrome desktop launcher not found."
    exit 1
fi

# Copy launcher to user's desktop
cp "${APP_DESKTOP}" "${DESKTOP_DIR}/google-chrome.desktop"

# Make launcher executable
chmod 755 "${DESKTOP_DIR}/google-chrome.desktop"

# Ensure correct ownership
chown 1000:0 "${DESKTOP_DIR}/google-chrome.desktop"

# Cleanup
rm -f "${CHROME_DEB}"

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[Chrome] Installation completed successfully."
