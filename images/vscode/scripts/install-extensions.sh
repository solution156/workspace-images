#!/usr/bin/env bash
set -Eeuo pipefail

manifest="${EXTENSIONS_MANIFEST:-/opt/dwf-vscode/extensions.txt}"
lockfile="${EXTENSIONS_LOCK:-/opt/dwf-vscode/extensions.lock}"
output="${GENERATED_LOCK:-/opt/dwf-vscode/extensions.lock.generated}"
extensions_dir="${VSCODE_EXTENSIONS:-/opt/dwf-vscode/extensions}"
mode="${EXTENSION_MODE:-locked}"

[[ "$mode" == "resolve" || "$mode" == "locked" ]] || {
  echo "[ERROR] EXTENSION_MODE must be resolve or locked" >&2; exit 2;
}
[[ "$(id -u)" != "0" ]] || { echo "[ERROR] Do not install extensions as root" >&2; exit 1; }
command -v code >/dev/null || { echo "[ERROR] VS Code binary unavailable" >&2; exit 1; }
[[ -d "$extensions_dir" && -w "$extensions_dir" ]] || {
  echo "[ERROR] Extension directory is not writable: $extensions_dir" >&2; exit 1;
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$mode" == "locked" ]]; then
  EXTENSIONS_MANIFEST="$manifest" EXTENSIONS_LOCK="$lockfile" \
    "$script_dir/verify-extensions.sh" --require-lock
else
  EXTENSIONS_MANIFEST="$manifest" EXTENSIONS_LOCK="$lockfile" \
    "$script_dir/verify-extensions.sh" --manifest-only
fi

# Extract IDs/versions only after the manifest and lockfile have been validated.
declare -a required=()
declare -A requested=() pinned=() installed=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  read -r id _ <<< "$line" || :
  [[ -n "${id:-}" ]] || continue
  required+=("$id")
  requested["${id,,}"]="$id"
done < "$manifest"
if [[ "$mode" == "locked" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    read -r spec _ <<< "$line" || :
    [[ -n "${spec:-}" ]] || continue
    id="${spec%@*}"
    pinned["${id,,}"]="${spec##*@}"
  done < "$lockfile"
fi

# Marketplace downloads can time out through a proxy. Retry only transient
# network failures; a bad ID or missing version still fails on the first try.
install_extension() {
  local spec="$1" attempt=1 output
  local transient='ETIMEDOUT|ECONNRESET|ECONNREFUSED|EAI_AGAIN|ESOCKETTIMEDOUT|socket hang up'
  while :; do
    if output="$(code --install-extension "$spec" --extensions-dir "$extensions_dir" --force 2>&1)"; then
      [[ -z "$output" ]] || printf '%s\n' "$output"
      return 0
    fi
    [[ -z "$output" ]] || printf '%s\n' "$output" >&2
    if ! grep -Eqi "$transient" <<< "$output"; then
      echo "[ERROR] Failed to install $spec" >&2
      return 1
    fi
    if (( attempt >= 3 )); then
      echo "[ERROR] Failed to install $spec after 3 attempts" >&2
      return 1
    fi
    echo "[WARN] Transient network error for $spec (attempt ${attempt}/3); retrying in 5s" >&2
    sleep 5
    attempt=$((attempt + 1))
  done
}

printf '[INFO] VS Code version: '; code --version | head -n 1
for id in "${required[@]}"; do
  spec="$id"
  [[ "$mode" == "resolve" ]] || spec="$id@${pinned[${id,,}]}"
  echo "[INFO] Installing $spec"
  # Installing into a controlled directory ensures persistent HOME mounts do not
  # shadow the image's baseline extensions. No silent skip for missing IDs.
  install_extension "$spec"
done

if [[ "$mode" == "locked" ]]; then
  EXTENSIONS_MANIFEST="$manifest" EXTENSIONS_LOCK="$lockfile" \
    "$script_dir/verify-extensions.sh" --runtime
  exit 0
fi

# Resolve mode is a controlled bootstrap step. Persist *actual* installed versions
# so future builds can use the lockfile and fail rather than drifting silently.
actual_file="$(mktemp)"
trap 'rm -f "$actual_file"' EXIT
code --list-extensions --show-versions --extensions-dir "$extensions_dir" > "$actual_file"
while IFS= read -r spec || [[ -n "$spec" ]]; do
  spec="${spec%$'\r'}"
  [[ "$spec" == *@* ]] || continue
  key="${spec%@*}"
  installed["${key,,}"]="${spec##*@}"
done < "$actual_file"
: > "$output"
for id in "${required[@]}"; do
  key="${id,,}"
  ver="${installed[$key]:-}"
  [[ -n "$ver" ]] || { echo "[ERROR] Missing after install: $id" >&2; exit 1; }
  printf '%s@%s\n' "$id" "$ver" >> "$output"
done
EXTENSIONS_MANIFEST="$manifest" EXTENSIONS_LOCK="$output" \
  "$script_dir/verify-extensions.sh" --runtime
printf '[OK] Wrote verified lockfile: %s\n' "$output"
