#!/usr/bin/env bash
set -Eeuo pipefail

echo "[CloudMonkey] Installing cmk..."
CMK_VERSION="6.6.0"
CMK_SHA256="9f4f92ebc3b1e6139d81a2b3f9e7f7c663d1806234ae0ab27cf77753c553d76b"

ARCH="$(dpkg --print-architecture)"
if [[ "${ARCH}" != "amd64" ]]; then
  echo "[CloudMonkey] Unsupported architecture: ${ARCH}"
  exit 1
fi

CMK_URL="https://github.com/apache/cloudstack-cloudmonkey/releases/download/${CMK_VERSION}/cmk.linux.x86-64"
curl -fSL --retry 3 "${CMK_URL}" -o /usr/local/bin/cmk
echo "${CMK_SHA256}  /usr/local/bin/cmk" | sha256sum -c -
chmod 0755 /usr/local/bin/cmk
cmk version
echo "[CloudMonkey] Installation completed successfully."