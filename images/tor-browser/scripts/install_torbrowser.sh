#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Tor] Installing Tor Browser..."

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TOR_VERSION="${TOR_VERSION:-latest}"
TOR_INSTALL_DIR="/opt/tor-browser"
TOR_SIGNING_KEY="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"

UBOL_XPI_URL="${UBOL_XPI_URL:-https://addons.mozilla.org/firefox/downloads/latest/ublock-origin-lite/latest.xpi}"
UBOL_ID="uBOLiteRedux@raymondhill.net"

DIST_DIR="${TOR_INSTALL_DIR}/Browser/distribution"

# --------------------------------------------------
# Validate architecture
# --------------------------------------------------
ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
  echo "[Tor] Unsupported architecture: ${ARCH}"
  exit 1
fi

# --------------------------------------------------
# Install dependencies
# --------------------------------------------------
apt-get update

apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  dirmngr \
  xz-utils \
  jq \
  unzip \
  libgtk-3-0t64 \
  libdbus-glib-1-2 \
  libasound2t64 \
  libx11-xcb1 \
  libxt6t64 \
  libxtst6

# --------------------------------------------------
# Resolve version
# --------------------------------------------------
if [[ "${TOR_VERSION}" == "latest" ]]; then
  echo "[Tor] Resolving latest stable version..."
  TOR_VERSION="$(curl -fsSL --retry 3 \
    https://aus1.torproject.org/torbrowser/update_3/release/downloads.json \
    | jq -r '.version')"
fi

if [[ -z "${TOR_VERSION}" || "${TOR_VERSION}" == "null" ]]; then
  echo "[Tor] ERROR: cannot determine Tor Browser version."
  exit 1
fi

echo "[Tor] Version: ${TOR_VERSION}"

# --------------------------------------------------
# Download + verify signature
# --------------------------------------------------
TOR_TARBALL="/tmp/tor-browser.tar.xz"
TOR_ASC="/tmp/tor-browser.tar.xz.asc"
TOR_BASE_URL="https://dist.torproject.org/torbrowser/${TOR_VERSION}"
TOR_FILE="tor-browser-linux-x86_64-${TOR_VERSION}.tar.xz"

curl -fSL --retry 3 "${TOR_BASE_URL}/${TOR_FILE}" -o "${TOR_TARBALL}"
curl -fSL --retry 3 "${TOR_BASE_URL}/${TOR_FILE}.asc" -o "${TOR_ASC}"

echo "[Tor] Verifying GPG signature..."

export GNUPGHOME
GNUPGHOME="$(mktemp -d)"
chmod 700 "${GNUPGHOME}"

TOR_KEY_URL="https://keys.openpgp.org/vks/v1/by-fingerprint/${TOR_SIGNING_KEY}"

echo "[Tor] Downloading Tor signing key..."

curl -fSL --retry 3 "${TOR_KEY_URL}" \
    -o /tmp/tor-signing-key.asc

echo "[Tor] Importing signing key..."

gpg --batch --import /tmp/tor-signing-key.asc

IMPORTED_KEY="$(gpg --batch --with-colons --fingerprint \
    torbrowser@torproject.org | awk -F: '$1 == "fpr" {print $10; exit}')"

if [[ "${IMPORTED_KEY}" != "${TOR_SIGNING_KEY}" ]]; then
    echo "[Tor] ERROR: unexpected signing key fingerprint."
    exit 1
fi

VERIFY_OUT="$(gpg --batch --status-fd 1 --verify "${TOR_ASC}" "${TOR_TARBALL}" 2>/dev/null)" || {
  echo "[Tor] ERROR: signature verification failed."
  exit 1
}

if ! grep -q "VALIDSIG .*${TOR_SIGNING_KEY}" <<< "${VERIFY_OUT}"; then
  echo "[Tor] ERROR: signature not made by the expected Tor Browser signing key."
  exit 1
fi

rm -rf "${GNUPGHOME}"
unset GNUPGHOME

# --------------------------------------------------
# Extract
# --------------------------------------------------
rm -rf "${TOR_INSTALL_DIR}"
tar -xJf "${TOR_TARBALL}" -C /opt

if [[ ! -x "${TOR_INSTALL_DIR}/Browser/start-tor-browser" ]]; then
  echo "[Tor] ERROR: start-tor-browser not found after extraction."
  exit 1
fi

# --------------------------------------------------
# uBlock Origin Lite
# --------------------------------------------------
echo "[uBOL] Downloading uBlock Origin Lite..."

mkdir -p "${DIST_DIR}"
curl -fSL --retry 3 "${UBOL_XPI_URL}" -o "${DIST_DIR}/ublock-origin-lite.xpi"

FOUND_ID="$(unzip -p "${DIST_DIR}/ublock-origin-lite.xpi" manifest.json \
  | jq -r '.browser_specific_settings.gecko.id // .applications.gecko.id // empty')"

if [[ "${FOUND_ID}" != "${UBOL_ID}" ]]; then
  echo "[uBOL] ERROR: unexpected extension id '${FOUND_ID}' (expected '${UBOL_ID}')."
  echo "[uBOL] Update UBOL_XPI_URL or the id in policies.json."
  exit 1
fi

# --------------------------------------------------
# Enterprise policies (download dir + uBOL)
# Merge with the policies.json shipped by Tor Browser if it exists
# --------------------------------------------------
echo "[Tor] Applying policies..."

POLICIES_FILE="${INST_DIR}/policies.json"

if [[ ! -f "${POLICIES_FILE}" ]]; then
  echo "[Tor] ERROR: policies.json not found: ${POLICIES_FILE}"
  exit 1
fi

if [[ -f "${DIST_DIR}/policies.json" ]]; then
  jq -s '.[0] * .[1]' \
    "${DIST_DIR}/policies.json" \
    "${POLICIES_FILE}" \
    > /tmp/policies.merged.json

  mv /tmp/policies.merged.json "${DIST_DIR}/policies.json"
else
  cp "${POLICIES_FILE}" "${DIST_DIR}/policies.json"
fi

# --------------------------------------------------
# Permissions
# Tor Browser writes its profile inside its own folder -> must be writable by UID 1000
# --------------------------------------------------
chown -R 1000:0 "${TOR_INSTALL_DIR}"

# Policies + extension stay root-owned and read-only
chown -R root:root "${DIST_DIR}"
chmod 755 "${DIST_DIR}"
find "${DIST_DIR}" -type f -exec chmod 644 {} +

# --------------------------------------------------
# Cleanup
# --------------------------------------------------
rm -f "${TOR_TARBALL}" "${TOR_ASC}"

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[Tor] Installation completed successfully."