#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Chrome"

write_file /etc/default/google-chrome <<'EOF'
repo_add_once="false"
EOF

install_deb_url "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
rm -f /etc/apt/sources.list.d/google-chrome*

write_file /etc/opt/chrome/policies/managed/kasm.json <<'EOF'
{
  "DefaultBrowserSettingEnabled": false,
  "MetricsReportingEnabled": false,
  "BrowserSignin": 0,
  "SyncDisabled": true,
  "PasswordManagerEnabled": false,
  "PromotionalTabsEnabled": false
}
EOF

add_desktop_launcher "google-chrome.desktop" "${CHROMIUM_FLAGS}"
finish