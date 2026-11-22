#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "KeePassXC"

apt_install keepassxc xclip xsel
add_desktop_launcher "*keepassxc*.desktop"
finish
