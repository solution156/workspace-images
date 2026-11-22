#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Nextcloud"

apt_install nextcloud-desktop libqt5sql5-sqlite libsecret-1-0 gnome-keyring
add_desktop_launcher "*nextcloud*.desktop"
finish
