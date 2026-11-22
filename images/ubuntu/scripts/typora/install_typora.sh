#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Typora"

add_repo typora "https://typora.io/linux/public-key.asc" "https://typora.io/linux ./"
apt_install typora
add_desktop_launcher "typora.desktop" "${ELECTRON_FLAGS}"
finish
