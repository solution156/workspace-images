#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "XMind"

apt_install libgtk-3-0t64 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0t64 libsecret-1-0
install_deb_url "https://www.xmind.app/zen/download/linux_deb/"
add_desktop_launcher "*xmind*.desktop" "${ELECTRON_FLAGS}"
finish
