#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Opera] Installing Opera Stable ${OPERA_VERSION:-?} from .deb..."

export DEBIAN_FRONTEND=noninteractive

OPERA_VERSION="${OPERA_VERSION:-}"
OPERA_DEB_SHA256="${OPERA_DEB_SHA256:-}"
OPERA_DEB_URL="https://get.geo.opera.com/pub/opera/desktop/${OPERA_VERSION}/linux/opera-stable_${OPERA_VERSION}_amd64.deb"
OPERA_DEB_FILE="/tmp/opera-stable.deb"
POLICY_SRC="${INST_DIR}/policies.json"
POLICY_DST_DIR="/etc/opt/opera/policies/managed"

ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" != "amd64" ]]; then
  echo "[Opera] Unsupported architecture: ${ARCH}"
  exit 1
fi

if [[ -z "${OPERA_VERSION}" ]]; then
  echo "[Opera] ERROR: OPERA_VERSION chưa được đặt."
  exit 1
fi

if [[ -z "${OPERA_DEB_SHA256}" ]]; then
  echo "[Opera] ERROR: OPERA_DEB_SHA256 chưa được đặt."
  exit 1
fi

apt-get update
apt-get install -y --no-install-recommends ca-certificates curl

# --------------------------------------------------
# Tải .deb và kiểm tra sha256
# --------------------------------------------------
curl -fSL --retry 3 "${OPERA_DEB_URL}" -o "${OPERA_DEB_FILE}"
echo "${OPERA_DEB_SHA256}  ${OPERA_DEB_FILE}" | sha256sum -c -

# --------------------------------------------------
# Cài bằng apt để tự kéo dependency
# --------------------------------------------------
apt-get install -y --no-install-recommends "${OPERA_DEB_FILE}"
rm -f "${OPERA_DEB_FILE}"

if [[ ! -x /usr/bin/opera ]]; then
  echo "[Opera] ERROR: /usr/bin/opera not found after install."
  exit 1
fi

INSTALLED_VERSION="$(dpkg-query -W -f='${Version}' opera-stable)"
if [[ "${INSTALLED_VERSION}" != "${OPERA_VERSION}" ]]; then
  echo "[Opera] ERROR: installed ${INSTALLED_VERSION}, expected ${OPERA_VERSION}."
  exit 1
fi
echo "[Opera] Installed: ${INSTALLED_VERSION}"

# --------------------------------------------------
# Policies (root-owned, chỉ đọc với user)
# --------------------------------------------------
mkdir -p "${POLICY_DST_DIR}"
cp "${POLICY_SRC}" "${POLICY_DST_DIR}/kasm-policy.json"
chown -R root:root /etc/opt/opera
chmod 755 "${POLICY_DST_DIR}"
chmod 644 "${POLICY_DST_DIR}/kasm-policy.json"

# --------------------------------------------------
# Cleanup
# --------------------------------------------------
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "[Opera] Installation completed successfully."