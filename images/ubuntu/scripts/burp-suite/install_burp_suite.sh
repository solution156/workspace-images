#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Burp Suite Community"

BURP_DIR="/opt/BurpSuiteCommunity"
installer="$(mktemp --suffix=.sh)"

# Thư viện cho JRE GUI và Chromium Embedded Browser của Burp
apt_install libxtst6 libxrender1 libxi6 fontconfig libnss3 libatk-bridge2.0-0t64 libdrm2 libxkbcommon0 libgbm1 libasound2t64

curl -fSL --retry 3 \
  "https://portswigger.net/burp/releases/startdownload?product=community&type=Linux" \
  -o "${installer}"
chmod +x "${installer}"

"${installer}" -q -dir "${BURP_DIR}"
rm -f "${installer}"

[[ -x "${BURP_DIR}/BurpSuiteCommunity" ]] || die "Burp executable not found in ${BURP_DIR}"

# Hạ quyền SUID trên chrome-sandbox đi kèm Burp
find "${BURP_DIR}" -name "chrome-sandbox" -exec chmod 0755 {} + 2>/dev/null || true

icon="$(find "${BURP_DIR}" -maxdepth 2 -name '*.png' -print -quit || true)"
make_launcher "burpsuite-community" "Burp Suite Community" \
  "${BURP_DIR}/BurpSuiteCommunity" "${icon:-applications-internet}" "Development;Network;Security;"

finish
