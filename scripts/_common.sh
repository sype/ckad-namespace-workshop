#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034 # Consommée par les scripts qui sourcent ce fichier.
MANIFEST_DIR="${MANIFEST_DIR:-${ROOT_DIR}/solution/manifests}"
KUBECTL_BIN="${KUBECTL_BIN:-kubectl}"

command -v "${KUBECTL_BIN}" >/dev/null 2>&1 || {
  echo "Erreur: kubectl est introuvable." >&2
  exit 2
}

CURRENT_CONTEXT="$(${KUBECTL_BIN} config current-context 2>/dev/null || true)"
WORKSHOP_NAMESPACE="${WORKSHOP_NAMESPACE:-$(${KUBECTL_BIN} config view --minify -o jsonpath='{..namespace}' 2>/dev/null || true)}"

if [[ -z "${CURRENT_CONTEXT}" ]]; then
  echo "Erreur: aucun contexte Kubernetes actif." >&2
  exit 2
fi

case "${WORKSHOP_NAMESPACE}" in
  ""|default|kube-system|kube-public|kube-node-lease)
    echo "Erreur: namespace d'atelier invalide: '${WORKSHOP_NAMESPACE:-vide}'." >&2
    exit 2
    ;;
esac

k() {
  "${KUBECTL_BIN}" -n "${WORKSHOP_NAMESPACE}" "$@"
}
