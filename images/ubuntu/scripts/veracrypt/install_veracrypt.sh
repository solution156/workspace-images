#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"
init_app "VeraCrypt"

apt_install dmsetup fuse3 libfuse2t64 dosfstools exfatprogs

# Chốt ký tự $ ở cuối regex để không khớp nhầm file .deb.sig trên GitHub Releases
VERACRYPT_REGEX='^veracrypt-[0-9.]+-Ubuntu-24\.04-amd64\.deb$'
VERACRYPT_URL="$(gh_asset_url veracrypt/VeraCrypt "${VERACRYPT_REGEX}")"

log "Downloading VeraCrypt from: ${VERACRYPT_URL}"
install_deb_url "${VERACRYPT_URL}"

add_desktop_launcher "veracrypt*.desktop"
finish
