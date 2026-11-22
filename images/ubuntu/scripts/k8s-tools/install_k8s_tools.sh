#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/../lib/common.sh"

init_app "Kubernetes tools"

BIN=/usr/local/bin
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

dl() { curl -fSL --retry 3 "$@"; }

# kubectl
KUBECTL_VERSION="${KUBECTL_VERSION:-$(curl -fsSL https://dl.k8s.io/release/stable.txt)}"
dl -o "${BIN}/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

# helm
HELM_VERSION="${HELM_VERSION:-$(gh_latest_tag helm/helm)}"
dl "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xz -C "${tmp}"
mv "${tmp}/linux-amd64/helm" "${BIN}/helm"

# helmfile
HELMFILE_TAG="${HELMFILE_TAG:-$(gh_latest_tag helmfile/helmfile)}"
dl "https://github.com/helmfile/helmfile/releases/download/${HELMFILE_TAG}/helmfile_${HELMFILE_TAG#v}_linux_amd64.tar.gz" \
  | tar -xz -C "${BIN}" helmfile

# kustomize
( cd "${tmp}" && curl -fsSL https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh | bash )
mv "${tmp}/kustomize" "${BIN}/kustomize"

# k9s, talosctl, cilium-cli, yq
dl "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" | tar -xz -C "${BIN}" k9s
dl -o "${BIN}/talosctl" "https://github.com/siderolabs/talos/releases/latest/download/talosctl-linux-amd64"
dl "https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz" | tar -xz -C "${BIN}" cilium
dl -o "${BIN}/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"

chmod 0755 "${BIN}"/{kubectl,helm,helmfile,kustomize,k9s,talosctl,cilium,yq}

# Bash completion + alias k cho mọi user (bao gồm sdwf-user)
install -d /etc/bash_completion.d
"${BIN}/kubectl" completion bash > /etc/bash_completion.d/kubectl
"${BIN}/helm" completion bash > /etc/bash_completion.d/helm

if ! grep -q "alias k=kubectl" /etc/bash.bashrc; then
  cat >> /etc/bash.bashrc <<'EOF'

# Kubernetes shortcuts
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
fi

# Verify versions in build log
"${BIN}/kubectl" version --client
"${BIN}/helm" version --short
"${BIN}/helmfile" --version
"${BIN}/kustomize" version
"${BIN}/k9s" version --short
"${BIN}/talosctl" version --client
"${BIN}/cilium" version --client
"${BIN}/yq" --version

finish