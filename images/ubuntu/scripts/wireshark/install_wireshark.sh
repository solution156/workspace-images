#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Wireshark"

# Khai báo debconf để wireshark-common tạo group wireshark chuẩn
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

# Cài đặt cả wireshark (GUI), tshark (CLI) và libcap2-bin
apt_install wireshark tshark libcap2-bin

# 1. Đảm bảo group 'wireshark' tồn tại
getent group wireshark >/dev/null || groupadd -r wireshark

# 2. Thêm user UID 1000 hiện tại (ví dụ: kasm-user) và sdwf-user vào group wireshark
uid1000_user="$(id -nu 1000 2>/dev/null || true)"
if [[ -n "${uid1000_user}" ]]; then
  usermod -aG wireshark "${uid1000_user}"
fi

if id -u sdwf-user >/dev/null 2>&1; then
  usermod -aG wireshark sdwf-user
else
  # Trường hợp sdwf-user được tạo lúc runtime bởi platform, ghi danh sẵn vào /etc/group
  if ! grep -qE '^wireshark:.*(\bsdwf-user\b)' /etc/group; then
    if grep -qE '^wireshark:[^:]*:[^:]*:$' /etc/group; then
      sed -i 's/^\(wireshark:[^:]*:[^:]*:\)$/\1sdwf-user/' /etc/group
    else
      sed -i 's/^\(wireshark:.*\)$/\1,sdwf-user/' /etc/group
    fi
  fi
fi

# 3. Cấu hình quyền và Linux Capabilities cho binary thực của dumpcap
DUMPCAP_BIN="$(command -v dumpcap)"
[[ -n "${DUMPCAP_BIN}" ]] || die "dumpcap binary not found"
REAL_DUMPCAP="$(readlink -f "${DUMPCAP_BIN}")"
[[ -f "${REAL_DUMPCAP}" ]] || die "Resolved dumpcap binary does not exist: ${REAL_DUMPCAP}"

# Lưu ý: chown và chmod PHẢI chạy trước setcap vì kernel sẽ xóa capabilities khi thay đổi owner/mode
chown root:wireshark "${REAL_DUMPCAP}"
chmod 0755 "${REAL_DUMPCAP}"
setcap 'cap_net_raw,cap_net_admin+eip' "${REAL_DUMPCAP}"

# 4. Verify capabilities ngay trong lúc build
caps_out="$(getcap "${REAL_DUMPCAP}")"
log "Configured ${REAL_DUMPCAP} -> $(stat -c '%U:%G %a' "${REAL_DUMPCAP}") | ${caps_out}"
grep -q "cap_net_admin" <<<"${caps_out}" || die "Missing cap_net_admin on ${REAL_DUMPCAP}"
grep -q "cap_net_raw" <<<"${caps_out}" || die "Missing cap_net_raw on ${REAL_DUMPCAP}"

add_desktop_launcher "*wireshark*.desktop"
finish