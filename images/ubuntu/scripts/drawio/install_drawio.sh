#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "draw.io"

install_deb_url "$(gh_asset_url jgraph/drawio-desktop 'drawio-amd64-[0-9.]+\.deb$')"

f="$(find_desktop "drawio.desktop")"
patch_exec_flags "${f}" "${ELECTRON_FLAGS}"
if ! grep -q "DRAWIO_DISABLE_UPDATE" "${f}"; then
  sed -i -E "s|^Exec=|Exec=env DRAWIO_DISABLE_UPDATE=true |" "${f}"
fi
copy_to_desktop "${f}"

finish