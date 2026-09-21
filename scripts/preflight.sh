#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=scripts/_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

echo "Contexte  : ${CURRENT_CONTEXT}"
echo "Namespace : ${WORKSHOP_NAMESPACE}"
"${KUBECTL_BIN}" version

resources=(
  deployments.apps
  statefulsets.apps
  pods
  services
  secrets
  configmaps
  persistentvolumeclaims
  networkpolicies.networking.k8s.io
  limitranges
  resourcequotas
)

for resource in "${resources[@]}"; do
  for verb in create get patch delete; do
    if [[ "$(k auth can-i "${verb}" "${resource}")" != "yes" ]]; then
      echo "Droit manquant dans ${WORKSHOP_NAMESPACE}: ${verb} ${resource}" >&2
      exit 3
    fi
  done
done

for resource in pods deployments.apps statefulsets.apps; do
  for verb in list watch; do
    if [[ "$(k auth can-i "${verb}" "${resource}")" != "yes" ]]; then
      echo "Droit manquant dans ${WORKSHOP_NAMESPACE}: ${verb} ${resource}" >&2
      exit 3
    fi
  done
done

if [[ "$(k auth can-i create pods/exec)" != "yes" ]]; then
  echo "Droit manquant dans ${WORKSHOP_NAMESPACE}: create pods/exec" >&2
  exit 3
fi

if [[ "$("${KUBECTL_BIN}" auth can-i delete namespaces 2>/dev/null)" == "yes" ]]; then
  echo "Avertissement: ce kubeconfig peut supprimer des namespaces." >&2
fi

echo "OK: accès et permissions de l'atelier validés."
