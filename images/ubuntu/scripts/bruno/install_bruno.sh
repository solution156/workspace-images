#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Bruno"

install_deb_url "$(gh_asset_url usebruno/bruno 'amd64.*\.deb$')"
add_desktop_launcher "bruno.desktop" "${ELECTRON_FLAGS}"
finish
