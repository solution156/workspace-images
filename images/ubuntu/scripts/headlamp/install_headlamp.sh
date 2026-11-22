#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Headlamp"

install_deb_url "$(gh_asset_url kubernetes-sigs/headlamp '(amd64|x64).*\.deb$')"
add_desktop_launcher "headlamp.desktop" "${ELECTRON_FLAGS}"
finish
