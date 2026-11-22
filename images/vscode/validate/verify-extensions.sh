#!/usr/bin/env bash
set -Eeuo pipefail

manifest="${EXTENSIONS_MANIFEST:-/opt/dwf-vscode/extensions.txt}"
lockfile="${EXTENSIONS_LOCK:-/opt/dwf-vscode/extensions.lock}"
extensions_dir="${VSCODE_EXTENSIONS:-/opt/dwf-vscode/extensions}"
mode="${1:---runtime}"

case "$mode" in
  --manifest-only|--require-lock|--runtime) ;;
  *) echo "[ERROR] Usage: $0 [--manifest-only|--require-lock|--runtime]" >&2; exit 2 ;;
esac

[[ -r "$manifest" ]] || { echo "[ERROR] Missing manifest: $manifest" >&2; exit 1; }
[[ -r "$lockfile" ]] || { echo "[ERROR] Missing lockfile: $lockfile" >&2; exit 1; }

declare -A requested=() locked=() actual=()
declare -a ordered=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  read -r id _ <<< "$line" || :
  [[ -n "${id:-}" ]] || continue
  [[ "$id" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]] || {
    echo "[ERROR] Invalid extension ID: $id" >&2; exit 1;
  }
  key="${id,,}"
  [[ -z "${requested[$key]+yes}" ]] || {
    echo "[ERROR] Duplicate requested ID: $id" >&2; exit 1;
  }
  requested["$key"]="$id"
  ordered+=("$key")
done < "$manifest"
(( ${#ordered[@]} > 0 )) || { echo "[ERROR] Empty extensions.txt" >&2; exit 1; }

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  read -r spec _ <<< "$line" || :
  [[ -n "${spec:-}" ]] || continue
  [[ "$spec" =~ ^([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)@([0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?)$ ]] || {
    echo "[ERROR] Bad lock entry: $spec" >&2; exit 1;
  }
  key="${BASH_REMATCH[1],,}"
  ver="${BASH_REMATCH[2]}"
  [[ -n "${requested[$key]+yes}" ]] || { echo "[ERROR] Unrequested lock ID: $spec" >&2; exit 1; }
  [[ -z "${locked[$key]+yes}" ]] || { echo "[ERROR] Duplicate lock ID: $spec" >&2; exit 1; }
  locked["$key"]="$ver"
done < "$lockfile"

if (( ${#locked[@]} > 0 )); then
  for key in "${ordered[@]}"; do
    [[ -n "${locked[$key]+yes}" ]] || {
      echo "[ERROR] Missing lock entry: ${requested[$key]}" >&2; exit 1;
    }
  done
elif [[ "$mode" != "--manifest-only" ]]; then
  echo "[ERROR] Lockfile uninitialized. Run the extension-lock bootstrap Docker build first." >&2
  exit 1
fi

if [[ "$mode" == "--manifest-only" ]]; then
  echo "[OK] Manifest entries: ${#ordered[@]}; locked: ${#locked[@]}"
  exit 0
fi
if [[ "$mode" == "--require-lock" ]]; then
  echo "[OK] Lockfile matches ${#ordered[@]} required extension IDs"
  exit 0
fi

command -v code >/dev/null || { echo "[ERROR] VS Code executable not in PATH" >&2; exit 1; }
[[ -d "$extensions_dir" ]] || { echo "[ERROR] Missing extensions directory: $extensions_dir" >&2; exit 1; }

actual_file="$(mktemp)"
trap 'rm -f "$actual_file"' EXIT
if ! code --list-extensions --show-versions --extensions-dir "$extensions_dir" > "$actual_file"; then
  echo "[ERROR] VS Code extension inventory command failed" >&2; exit 1
fi
while IFS= read -r spec || [[ -n "$spec" ]]; do
  spec="${spec%$'\r'}"
  [[ "$spec" == *@* ]] || continue
  key="${spec%@*}"
  key="${key,,}"
  actual["$key"]="${spec##*@}"
done < "$actual_file"

fail=0
for key in "${ordered[@]}"; do
  id="${requested[$key]}"
  if [[ -z "${actual[$key]+yes}" ]]; then
    echo "[ERROR] Not installed: $id" >&2
    fail=1
  elif [[ "${actual[$key]}" != "${locked[$key]}" ]]; then
    echo "[ERROR] Wrong version: $id expected=${locked[$key]} actual=${actual[$key]}" >&2
    fail=1
  fi
done
(( fail == 0 )) || exit 1
echo "[OK] Verified ${#ordered[@]} pinned extensions with VS Code CLI"
