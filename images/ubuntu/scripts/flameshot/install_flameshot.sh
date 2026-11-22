#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Flameshot"

apt_install flameshot

write_user_file ".config/flameshot/flameshot.ini" <<'EOF'
[General]
checkForUpdates=false
showStartupLaunchMessage=false
showHelp=false
EOF

f="$(find_desktop "*flameshot*.desktop")"
sed -i -E "s|^Exec=flameshot( .*)?$|Exec=flameshot gui|" "${f}"
copy_to_desktop "${f}"

finish