#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCENARIO="${1:-}"
case "${SCENARIO}" in
  service-routing|network-policy) ;;
  *) echo "Usage: $0 {service-routing|network-policy}" >&2; exit 2 ;;
esac

export WORKSHOP_NAMESPACE="${WORKSHOP_NAMESPACE:-$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)}"
case "${WORKSHOP_NAMESPACE}" in
  ckad-*|workshop-*) ;;
  *) echo "WORKSHOP_NAMESPACE doit commencer par ckad- ou workshop-." >&2; exit 2 ;;
esac

"${ROOT_DIR}/scenarios/${SCENARIO}/setup.sh"
printf '\nScénario prêt. Suivez scenarios/%s/student/README.md\n' "${SCENARIO}"
