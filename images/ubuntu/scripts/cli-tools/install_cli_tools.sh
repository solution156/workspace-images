#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "CLI & Network Tools"

apt_install \
  git bash bash-completion tmux jq openssl curl wget ca-certificates gnupg \
  dnsutils netcat-openbsd iperf3 iproute2 iputils-ping \
  mtr-tiny traceroute nmap masscan tcpdump libcap2-bin

# Cấp Linux capabilities tối thiểu cho binary thực (resolve symlink bằng readlink -f, KHÔNG SUID, KHÔNG sudo)
for bin in nmap tcpdump masscan; do
  if command -v "${bin}" >/dev/null 2>&1; then
    real_bin="$(readlink -f "$(command -v "${bin}")")"
    chmod 0755 "${real_bin}"
    setcap 'cap_net_raw,cap_net_admin+eip' "${real_bin}" || log "WARN: setcap failed for ${bin}"
  fi
done

for bin in mtr-packet ping traceroute.db; do
  if command -v "${bin}" >/dev/null 2>&1; then
    real_bin="$(readlink -f "$(command -v "${bin}")")"
    chmod 0755 "${real_bin}"
    setcap 'cap_net_raw+ep' "${real_bin}" || log "WARN: setcap failed for ${bin}"
  fi
done

finish