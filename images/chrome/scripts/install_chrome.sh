# #!/usr/bin/env bash
# set -Eeuo pipefail

# echo "[Chrome] Installing Google Chrome Stable..."

# export DEBIAN_FRONTEND=noninteractive

# # --------------------------------------------------
# # Chrome version
# # --------------------------------------------------


# CHROME_VERSION="${CHROME_VERSION:-157.0.8103.38}"
# CHROME_DEB="/tmp/google-chrome-stable.deb"

# # Validate architecture
# ARCH="$(dpkg --print-architecture)"

# if [[ "$ARCH" != "amd64" ]]; then
#     echo "[Chrome] Unsupported architecture: ${ARCH}"
#     exit 1
# fi

# # --------------------------------------------------
# # Install dependencies
# # --------------------------------------------------

# apt-get update

# apt-get install -y --no-install-recommends \
#     ca-certificates \
#     curl

# # --------------------------------------------------
# # Download pinned Chrome version
# # --------------------------------------------------

# echo "[Chrome] Downloading version ${CHROME_VERSION}..."

# CHROME_URL="https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb"

# curl -fSL --retry 3 \
#     "${CHROME_URL}" \
#     -o "${CHROME_DEB}"

# # Verify downloaded package version
# DOWNLOADED_VERSION="$(dpkg-deb -f "${CHROME_DEB}" Version)"

# if [[ "${DOWNLOADED_VERSION}" != "${CHROME_VERSION}-1" ]]; then
#     echo "[Chrome] ERROR: Expected ${CHROME_VERSION}-1, got ${DOWNLOADED_VERSION}"
#     exit 1
# fi

# # --------------------------------------------------
# # Install Chrome
# # --------------------------------------------------

# apt-get install -y --no-install-recommends "${CHROME_DEB}"

# # Verify installed version
# INSTALLED_VERSION="$(google-chrome --version | awk '{print $3}')"

# if [[ "${INSTALLED_VERSION}" != "${CHROME_VERSION}" ]]; then
#     echo "[Chrome] ERROR: Expected ${CHROME_VERSION}, got ${INSTALLED_VERSION}"
#     exit 1
# fi

# # Prevent automatic Chrome upgrades
# apt-mark hold google-chrome-stable

# echo "[Chrome] Installed version: ${INSTALLED_VERSION}"

# # --------------------------------------------------
# # Security updates
# # --------------------------------------------------

# echo "[Security] Updating vulnerable packages..."

# apt-get update

# apt-get install -y --only-upgrade \
#     apt \
#     libapt-pkg6.0t64 \
#     libbrotli1

# echo "[Security] Security updates completed."

# # --------------------------------------------------
# # Desktop launcher
# # --------------------------------------------------

# DESKTOP_DIR="${HOME}/Desktop"
# APP_DESKTOP="/usr/share/applications/google-chrome.desktop"

# mkdir -p "${DESKTOP_DIR}"

# if [[ ! -f "${APP_DESKTOP}" ]]; then
#     echo "[Chrome] ERROR: Chrome desktop launcher not found."
#     exit 1
# fi

# # Copy launcher to user's desktop
# cp "${APP_DESKTOP}" "${DESKTOP_DIR}/google-chrome.desktop"

# # Make launcher executable
# chmod 755 "${DESKTOP_DIR}/google-chrome.desktop"

# # Ensure correct ownership
# chown 1000:0 "${DESKTOP_DIR}/google-chrome.desktop"

# # --------------------------------------------------
# # Cleanup
# # --------------------------------------------------

# rm -f "${CHROME_DEB}"

# apt-get clean
# rm -rf /var/lib/apt/lists/*

# echo "[Chrome] Installation completed successfully."


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
CHROME_URL="https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_VERSION}-1_amd64.deb"

echo "[Chrome] Downloading version ${CHROME_VERSION}..."
curl -fSL --retry 3 "${CHROME_URL}" -o "${CHROME_DEB}"

# Install Chrome
apt-get install -y --no-install-recommends "${CHROME_DEB}"

apt-mark hold google-chrome-stable
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
