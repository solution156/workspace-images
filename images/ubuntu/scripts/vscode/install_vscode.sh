#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "VS Code"

echo "code code/add-microsoft-repo boolean false" | debconf-set-selections
add_repo vscode "https://packages.microsoft.com/keys/microsoft.asc" "https://packages.microsoft.com/repos/code stable main"
apt_install code
rm -f /etc/apt/sources.list.d/vscode.sources

write_user_file ".config/Code/User/settings.json" <<'EOF'
{
  "telemetry.telemetryLevel": "off",
  "update.mode": "none",
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "workbench.startupEditor": "none",
  "workbench.tips.enabled": false,
  "workbench.enableExperiments": false,
  "security.workspace.trust.enabled": false,
  "git.confirmSync": false
}
EOF

log "Desktop files shipped by package 'code':"
dpkg -L code | grep -E '\.desktop$' || log "(none)"

desktop="$(dpkg -L code | grep -E '/[^/]+\.desktop$' | grep -vi 'url' | sed -n '1p' || true)"
if [[ -n "${desktop}" && -f "${desktop}" ]]; then
  patch_exec_flags "${desktop}" "${ELECTRON_FLAGS}"
  copy_to_desktop "${desktop}"
else
  log "WARN: package has no usable .desktop file, creating one"
  make_launcher "code" "Visual Studio Code" \
    "/usr/share/code/code ${ELECTRON_FLAGS} %F" "vscode" "Development;IDE;"
fi

finish