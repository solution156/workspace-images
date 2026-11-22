#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Firefox] Installing Firefox ${FIREFOX_VERSION}..."

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# Validate environment
# --------------------------------------------------

: "${FIREFOX_VERSION:?FIREFOX_VERSION chưa được đặt}"

ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
    echo "[Firefox] Unsupported architecture: ${ARCH}"
    exit 1
fi

# --------------------------------------------------
# Install dependencies
# --------------------------------------------------
cat > /etc/apt/apt.conf.d/80-retries << 'EOF'
Acquire::Retries "5";
Acquire::http::Timeout "30";
Acquire::http::No-Cache "true";
EOF

apt-get update

apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    libgtk-3-0t64 \
    libdbus-glib-1-2 \
    libdbus-1-3 \
    libasound2t64 \
    libxt6t64 \
    libx11-xcb1 \
    libnss3 \
    fonts-liberation

# --------------------------------------------------
# Download Firefox tarball and checksum file
# --------------------------------------------------

FF_BASE="https://ftp.mozilla.org/pub/firefox/releases/${FIREFOX_VERSION}"
FF_PATH="linux-x86_64/en-US/firefox-${FIREFOX_VERSION}.tar.xz"
FF_TARBALL="/tmp/firefox-${FIREFOX_VERSION}.tar.xz"
FF_SUMS="/tmp/firefox-SHA512SUMS"

echo "[Firefox] Downloading ${FF_BASE}/${FF_PATH}..."
curl -fSL --retry 3 "${FF_BASE}/${FF_PATH}" -o "${FF_TARBALL}"
curl -fSL --retry 3 "${FF_BASE}/SHA512SUMS" -o "${FF_SUMS}"

# --------------------------------------------------
# Verify SHA512
# --------------------------------------------------

echo "[Firefox] Verifying checksum..."

EXPECTED_SHA512="$(awk -v p="${FF_PATH}" '$2 == p {print $1}' "${FF_SUMS}")"

if [[ -z "${EXPECTED_SHA512}" ]]; then
    echo "[Firefox] ERROR: Không tìm thấy checksum cho ${FF_PATH}"
    exit 1
fi

echo "${EXPECTED_SHA512}  ${FF_TARBALL}" | sha512sum -c -

# --------------------------------------------------
# Install Firefox to /opt/firefox
# --------------------------------------------------

rm -rf /opt/firefox
tar -xJf "${FF_TARBALL}" -C /opt

ln -sf /opt/firefox/firefox /usr/local/bin/firefox

# --------------------------------------------------
# Cleanup
# --------------------------------------------------

rm -f "${FF_TARBALL}" "${FF_SUMS}"

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[Firefox] Installation completed successfully."