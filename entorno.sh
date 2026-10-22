#!/usr/bin/env bash
P9_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$P9_DIR/herramientas:$PATH"
export KUBECONFIG="$P9_DIR/.local/kubeconfig"
export HELM_CONFIG_HOME="$P9_DIR/.local/helm/config"
export HELM_CACHE_HOME="$P9_DIR/.local/helm/cache"
export HELM_DATA_HOME="$P9_DIR/.local/helm/data"
