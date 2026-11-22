#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "Kleopatra"

apt_install kleopatra gnupg gnupg-agent dirmngr gpgsm scdaemon pinentry-gtk2 paperkey
add_desktop_launcher "*kleopatra*.desktop"
finish
