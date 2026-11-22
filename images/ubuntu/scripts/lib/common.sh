#!/usr/bin/env bash
# lib/common.sh - hàm dùng chung cho mọi script cài đặt
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive

APPS_DIR="/usr/share/applications"
export HOME="${HOME:-/home/kasm-default-profile}"
DESKTOP_DIR="${HOME}/Desktop"
APT_UPDATED_STAMP="/tmp/.apt_updated"

# 0 = thiếu launcher chỉ cảnh báo, 1 = thiếu launcher thì dừng build
LAUNCHER_STRICT="${LAUNCHER_STRICT:-0}"

# Giúp app Chromium/Electron chạy trong container, không hỏi keyring, tắt GPU sandbox crash
ELECTRON_FLAGS="--no-sandbox --disable-gpu-sandbox --password-store=basic"
CHROMIUM_FLAGS="--no-sandbox --disable-gpu-sandbox --password-store=basic --no-first-run --no-default-browser-check"

log() { echo "[${APP_NAME:-install}] $*"; }
die() { log "ERROR: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Vòng đời script: init_app ... finish
# ---------------------------------------------------------------------------
init_app() {
  APP_NAME="$1"
  [[ "${EUID}" -eq 0 ]] || die "Please run as root."
  [[ "$(dpkg --print-architecture)" == "amd64" ]] || die "Only amd64 is supported."
  mkdir -p "${DESKTOP_DIR}"

  # Retry tải file apt, chống mạng/proxy chập chờn
  mkdir -p /etc/apt/apt.conf.d
  cat > /etc/apt/apt.conf.d/98build <<'EOF'
Acquire::Retries "5";
Acquire::http::Pipeline-Depth "0";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

  # Ghi nhớ các repo đang có để finish() xoá repo mà script này thêm
  REPOS_BEFORE="$(ls -1 /etc/apt/sources.list.d 2>/dev/null || true)"
  log "Installing..."
}

finish() {
  local f repo_removed=0
  for f in /etc/apt/sources.list.d/*; do
    [[ -e "${f}" ]] || continue
    if ! grep -qxF "$(basename "${f}")" <<<"${REPOS_BEFORE:-}"; then
      log "Removing build-time repo: ${f}"
      rm -f "${f}"
      repo_removed=1
    fi
  done
  if [[ "${repo_removed}" -eq 1 ]]; then
    rm -f "${APT_UPDATED_STAMP}"
  fi
  apt-get clean
  log "Installation completed successfully."
}

# ---------------------------------------------------------------------------
# APT (Tối ưu hóa tránh apt-get update lặp lại không cần thiết)
# ---------------------------------------------------------------------------
apt_update() {
  if [[ -f "${APT_UPDATED_STAMP}" ]] && [[ -n "$(ls -A /var/lib/apt/lists 2>/dev/null || true)" ]]; then
    return 0
  fi
  local i
  for i in 1 2 3 4 5; do
    if apt-get update; then
      touch "${APT_UPDATED_STAMP}"
      return 0
    fi
    log "apt-get update failed (attempt ${i}/5), retrying in 20s..."
    sleep 20
    rm -rf /var/lib/apt/lists/* "${APT_UPDATED_STAMP}"
  done
  die "apt-get update failed after 5 attempts"
}

apt_install() {
  apt_update
  apt-get install -y --no-install-recommends "$@"
}

# Thêm APT repo: tự động kiểm tra định dạng ASCII PGP hay binary để dearmor về .gpg chuẩn
add_repo() {
  local name="$1" key="$2" line="$3"
  local tmp_key
  tmp_key="$(mktemp)"
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL --retry 3 "${key}" -o "${tmp_key}"
  if grep -q "BEGIN PGP PUBLIC KEY BLOCK" "${tmp_key}"; then
    gpg --batch --yes --dearmor -o "/etc/apt/keyrings/${name}.gpg" "${tmp_key}"
  else
    cp -f "${tmp_key}" "/etc/apt/keyrings/${name}.gpg"
  fi
  rm -f "${tmp_key}"
  chmod 0644 "/etc/apt/keyrings/${name}.gpg"
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/${name}.gpg] ${line}" > "/etc/apt/sources.list.d/${name}.list"
  rm -f "${APT_UPDATED_STAMP}"
}

# ---------------------------------------------------------------------------
# Tải .deb & GitHub Releases
# ---------------------------------------------------------------------------
install_deb_url() {
  local url="$1" f
  f="$(mktemp --suffix=.deb)"
  curl -fSL --retry 3 "${url}" -o "${f}"
  dpkg-deb -I "${f}" >/dev/null 2>&1 || die "Downloaded file is not a valid .deb: ${url}"
  apt_install "${f}"
  rm -f "${f}"
}

gh_asset_url() {
  local repo="$1"
  local regex="$2"
  local release_json
  local url
  local auth=()
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  command -v jq >/dev/null 2>&1 || die "jq is required for gh_asset_url"
  release_json="$(curl -fsSL --retry 3 "${auth[@]}" \
    "https://api.github.com/repos/${repo}/releases/latest")" \
    || die "Failed to fetch latest release from ${repo}"
  url="$(jq -r --arg regex "${regex}" \
    '[.assets[]? | select(.name | test($regex)) | .browser_download_url] | .[0] // empty' \
    <<< "${release_json}")"
  [[ -n "${url}" ]] || die "No asset matching '${regex}' in latest release of ${repo}"
  echo "${url}"
}

gh_latest_tag() {
  curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's|.*/tag/||'
}

# ---------------------------------------------------------------------------
# Launcher trên Desktop
# ---------------------------------------------------------------------------
find_desktop() {
  local f
  f="$(find "${APPS_DIR}" -maxdepth 1 -iname "$1" -print -quit)"
  if [[ -z "${f}" ]]; then
    log "WARN: desktop launcher not found: $1"
    if [[ "${LAUNCHER_STRICT}" == "1" ]]; then
      die "Desktop launcher not found: $1"
    fi
    return 1
  fi
  echo "${f}"
}

patch_exec_flags() {
  local file="$1" flags="$2"
  if ! grep -qF -- "--no-sandbox" "${file}"; then
    sed -i -E "s|^(Exec=(env ([^ ]+=[^ ]+ )*)?[^ ]+)|\1 ${flags}|g" "${file}"
  fi
}

copy_to_desktop() {
  local dst="${DESKTOP_DIR}/$(basename "$1")"
  cp -f "$1" "${dst}"
  chmod 0755 "${dst}"
  chown 1000:0 "${dst}"
}

add_desktop_launcher() {
  local f
  f="$(find_desktop "$1")" || return 0
  if [[ -n "${2:-}" ]]; then
    patch_exec_flags "${f}" "$2"
  fi
  copy_to_desktop "${f}"
}

make_launcher() {
  cat > "${APPS_DIR}/$1.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Icon=$4
Terminal=false
Categories=$5
StartupNotify=true
EOF
  copy_to_desktop "${APPS_DIR}/$1.desktop"
}

# ---------------------------------------------------------------------------
# Ghi file cấu hình đồng thời vào $HOME và /etc/skel (đảm bảo sdwf-user nhận đủ)
# ---------------------------------------------------------------------------
write_user_file() {
  local p="${HOME}/$1"
  local skel_p="/etc/skel/$1"
  local content
  content="$(cat)"
  mkdir -p "$(dirname "${p}")" "$(dirname "${skel_p}")"
  printf '%s\n' "${content}" > "${p}"
  printf '%s\n' "${content}" > "${skel_p}"
  chown -R 1000:0 "${HOME}/$(echo "$1" | cut -d/ -f1)"
}

write_file() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
}