#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "OpenVPN 3"

source /etc/os-release
[[ "${ID}" == "ubuntu" && -n "${VERSION_CODENAME:-}" ]] || die "Ubuntu with a codename is required."

add_repo openvpn3 \
  "https://packages.openvpn.net/packages-repo.gpg" \
  "https://packages.openvpn.net/openvpn3/debian ${VERSION_CODENAME} main"

apt_install dbus dbus-x11 openvpn openvpn3

finish