#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Firefox"

add_repo mozilla "https://packages.mozilla.org/apt/repo-signing-key.gpg" "https://packages.mozilla.org/apt mozilla main"

write_file /etc/apt/preferences.d/mozilla <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF

apt_install firefox

write_file /etc/firefox/policies/policies.json <<'EOF'
{
  "policies": {
    "DisableAppUpdate": true,
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableProfileImport": true,
    "DontCheckDefaultBrowser": true,
    "NoDefaultBookmarks": true,
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "UserMessaging": {
      "WhatsNew": false,
      "ExtensionRecommendations": false,
      "FeatureRecommendations": false,
      "UrlbarInterventions": false,
      "SkipOnboarding": true,
      "MoreFromMozilla": false
    }
  }
}
EOF

add_desktop_launcher "firefox.desktop"
finish