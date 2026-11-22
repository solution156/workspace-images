#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Git & Bash"

git config --system init.defaultBranch main
git config --system pull.rebase false
git config --system core.editor "nano"
git config --system safe.directory '*'

if find "${APPS_DIR}" -maxdepth 1 -name 'xfce4-terminal.desktop' | grep -q .; then
  add_desktop_launcher "xfce4-terminal.desktop"
else
  log "WARN: xfce4-terminal launcher not found, skipping Terminal shortcut"
fi

finish