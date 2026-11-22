#!/usr/bin/env bash
# Invoked by the CI runtime test using stdin in the image, no host installation.
set -Eeuo pipefail
command -v code >/dev/null
/opt/dwf-vscode/verify-extensions.sh --runtime
