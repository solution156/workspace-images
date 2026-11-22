#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Remote Desktop Manager"

RDM_VERSION="${RDM_VERSION:-2026.3.2.1}"
install_deb_url "https://cdn.devolutions.net/download/Linux/RDM/${RDM_VERSION}/RemoteDesktopManager_${RDM_VERSION}_amd64.deb"
add_desktop_launcher "*remotedesktopmanager*.desktop"
finish
