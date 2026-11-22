#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "ONLYOFFICE"

add_repo onlyoffice \
  "https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE" \
  "https://download.onlyoffice.com/repo/debian squeeze main"

apt_install onlyoffice-desktopeditors

# Verify installation
command -v desktopeditors >/dev/null
test -f /usr/share/applications/onlyoffice-desktopeditors.desktop

add_desktop_launcher "onlyoffice-desktopeditors.desktop"
finish