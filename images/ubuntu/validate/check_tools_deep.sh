#!/usr/bin/env bash
set -uo pipefail

PASS=0
FAIL=0

ok()   { echo "  [PASS] $*"; ((PASS++)); }
fail() { echo "  [FAIL] $*" >&2; ((FAIL++)); }

echo "=========================================="
echo "1. KIỂM TRA CURRENT USER & LEAST PRIVILEGE"
echo "=========================================="
echo "Current User: $(id)"
if sudo -n true 2>/dev/null; then
  fail "User có quyền passwordless sudo (rủi ro leo thang đặc quyền!)"
else
  ok "User KHÔNG có quyền passwordless sudo (Least Privilege OK)"
fi

if grep -qE '^wireshark:.*(kasm-user|sdwf-user)' /etc/group; then
  ok "Group 'wireshark' đã bao gồm non-root user: $(grep '^wireshark:' /etc/group)"
else
  fail "User chưa được thêm vào group 'wireshark' trong /etc/group"
fi

echo ""
echo "=========================================="
echo "2. KIỂM TRA CLI, K8S & NETWORK BINARIES"
echo "=========================================="
CLI_BINS=(
  git tmux jq yq openssl curl wget
  kubectl helm helmfile kustomize k9s talosctl cilium cmk
  mtr traceroute nmap masscan tcpdump dig nslookup nc iperf3
  wireshark tshark dumpcap
  code sublime_text bcompare veracrypt keepassxc flameshot
  typora kleopatra nextcloud desktopeditors
  google-chrome microsoft-edge firefox openvpn3
)

for cmd in "${CLI_BINS[@]}"; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    ok "Binary '${cmd}' -> $(command -v "${cmd}")"
  else
    fail "Missing binary: '${cmd}'"
  fi
done

echo ""
echo "=========================================="
echo "3. KIỂM TRA LINUX CAPABILITIES & DUMPCAP"
echo "=========================================="
if command -v dumpcap >/dev/null 2>&1; then
  real_dumpcap="$(readlink -f "$(command -v dumpcap)")"
  perms="$(stat -c '%a' "${real_dumpcap}")"
  owner_group="$(stat -c '%U:%G' "${real_dumpcap}")"
  caps="$(getcap "${real_dumpcap}" 2>/dev/null || true)"

  if [[ "${owner_group}" == "root:wireshark" ]] && \
     [[ "${perms}" == "755" || "${perms}" == "750" ]] && \
     [[ "${caps}" == *"cap_net_raw"* ]] && \
     [[ "${caps}" == *"cap_net_admin"* ]]; then
    ok "${real_dumpcap} (${owner_group}, mode ${perms}, không SUID) có capabilities chuẩn: ${caps}"
  else
    fail "${real_dumpcap} owner=${owner_group}, perms=${perms}, caps=${caps}"
  fi
else
  fail "Không tìm thấy binary dumpcap"
fi

echo ""
echo "=========================================="
echo "4. KIỂM TRA SHARED LIBRARIES (.so) BỊ THIẾU"
echo "=========================================="
ELF_TARGETS=(
  /usr/bin/wireshark
  /usr/bin/tshark
  /usr/bin/dumpcap
  /usr/bin/keepassxc
  /usr/bin/kleopatra
  /usr/bin/flameshot
  /usr/bin/nextcloud
  /usr/bin/veracrypt
)

if [[ -f /usr/lib/libreoffice/program/soffice.bin ]]; then
  ELF_TARGETS+=(/usr/lib/libreoffice/program/soffice.bin)
fi

for elf in "${ELF_TARGETS[@]}"; do
  if [[ -f "${elf}" ]]; then
    missing="$(ldd "${elf}" 2>/dev/null | grep 'not found' || true)"
    if [[ -z "${missing}" ]]; then
      ok "ldd '${elf}' đầy đủ thư viện"
    else
      fail "ldd '${elf}' thiếu thư viện: ${missing}"
    fi
  else
    fail "File thực thi không tồn tại: ${elf}"
  fi
done

echo ""
echo "=========================================="
echo "TỔNG KẾT: PASS=${PASS} | FAIL=${FAIL}"
echo "=========================================="
exit "${FAIL}"