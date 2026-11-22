#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Sublime Text"

add_repo sublime "https://download.sublimetext.com/sublimehq-pub.gpg" "https://download.sublimetext.com/ apt/stable/"
apt_install sublime-text

write_user_file ".config/sublime-text/Packages/User/Preferences.sublime-settings" <<'EOF'
{
  "update_check": false,
  "hot_exit": false,
  "remember_open_files": false
}
EOF

add_desktop_launcher "sublime_text.desktop"
finish