#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Microsoft Edge"

write_file /etc/default/microsoft-edge <<'EOF'
repo_add_once="false"
EOF

add_repo msedge "https://packages.microsoft.com/keys/microsoft.asc" "https://packages.microsoft.com/repos/edge stable main"
apt_install microsoft-edge-stable
rm -f /etc/apt/sources.list.d/microsoft-edge*

write_file /etc/opt/edge/policies/managed/kasm.json <<'EOF'
{
  "HideFirstRunExperience": true,
  "DefaultBrowserSettingEnabled": false,
  "BrowserSignin": 0,
  "SyncDisabled": true,
  "MetricsReportingEnabled": false,
  "PersonalizationReportingEnabled": false,
  "ShowRecommendationsEnabled": false,
  "EdgeShoppingAssistantEnabled": false,
  "PasswordManagerEnabled": false
}
EOF

add_desktop_launcher "microsoft-edge.desktop" "${CHROMIUM_FLAGS}"
finish