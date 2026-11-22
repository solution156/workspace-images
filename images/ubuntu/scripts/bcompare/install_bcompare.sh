#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Beyond Compare 4"

BC_VERSION="${BC_VERSION:-4.4.7.28397}"
install_deb_url "https://www.scootersoftware.com/files/bcompare-${BC_VERSION}_amd64.deb"
add_desktop_launcher "bcompare.desktop"
finish
