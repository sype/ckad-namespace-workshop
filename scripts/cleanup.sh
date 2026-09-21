#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=scripts/_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

echo "Namespace ciblé: ${WORKSHOP_NAMESPACE}"
if [[ "${CONFIRM_CLEANUP:-}" != "yes" ]]; then
  read -r -p "Supprimer les ressources de l'atelier ? [y/N] " answer
  [[ "${answer}" == "y" || "${answer}" == "Y" ]] || {
    echo "Nettoyage annulé."
    exit 0
  }
fi

k delete \
  -f "${MANIFEST_DIR}/11-test-backend.yaml" \
  -f "${MANIFEST_DIR}/10-test-frontend.yaml" \
  -f "${MANIFEST_DIR}/09-networkpolicy.yaml" \
  -f "${MANIFEST_DIR}/08-statefulset.yaml" \
  -f "${MANIFEST_DIR}/07-service-postgres.yaml" \
  -f "${MANIFEST_DIR}/06-configmap.yaml" \
  -f "${MANIFEST_DIR}/04-service.yaml" \
  -f "${MANIFEST_DIR}/03-deployment.yaml" \
  -f "${MANIFEST_DIR}/02-guardrails.yaml" \
  --ignore-not-found --wait=true
k delete secret db-secret --ignore-not-found
k delete pvc -l app.kubernetes.io/part-of=ckad-namespace-workshop \
  --ignore-not-found --wait=true

echo "OK: ressources supprimées. Le namespace est conservé."
