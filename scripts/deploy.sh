#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=scripts/_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

WORKSHOP_MODE="${WORKSHOP_MODE:-sequential}"
FRONTEND_REPLICAS="${FRONTEND_REPLICAS:-2}"
case "${WORKSHOP_MODE}" in
  sequential|full) ;;
  *)
    echo "Erreur: WORKSHOP_MODE doit valoir 'sequential' ou 'full'." >&2
    exit 2
    ;;
esac
case "${FRONTEND_REPLICAS}" in
  1|2) ;;
  *)
    echo "Erreur: FRONTEND_REPLICAS doit valoir 1 ou 2." >&2
    exit 2
    ;;
esac

echo "[1/4] Garde-fous"
k apply -f "${MANIFEST_DIR}/02-guardrails.yaml"
k get limitrange,resourcequota

echo "[2/4] Frontend et Service"
k apply -f "${MANIFEST_DIR}/03-deployment.yaml" -f "${MANIFEST_DIR}/04-service.yaml"
k scale deployment/web-app --replicas="${FRONTEND_REPLICAS}"
k rollout status deployment/web-app --timeout=180s
web_pod="$(k get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')"
k exec "${web_pod}" -- wget -qO- --timeout=5 http://web-svc >/dev/null
echo "OK: ${FRONTEND_REPLICAS} réplique(s) Nginx et Service HTTP validés."

if [[ "${WORKSHOP_MODE}" == "sequential" ]]; then
  echo "[3/4] Mode séquentiel: libération des pods frontend"
  k scale deployment/web-app --replicas=0
  k wait --for=delete pod -l app=frontend --timeout=120s
else
  echo "[3/4] Mode full: frontend conservé"
fi

echo "[4/4] PostgreSQL stateful"
if ! k get secret db-secret >/dev/null 2>&1; then
  command -v openssl >/dev/null 2>&1 || {
    echo "Erreur: openssl est nécessaire pour générer le mot de passe." >&2
    exit 2
  }
  db_password="$(openssl rand -hex 24)"
  "${KUBECTL_BIN}" create secret generic db-secret \
    --namespace "${WORKSHOP_NAMESPACE}" \
    --from-literal=username=workshop \
    --from-literal=database=workshop \
    --from-literal=password="${db_password}" \
    --dry-run=client -o yaml | k apply -f -
  unset db_password
fi

k apply \
  -f "${MANIFEST_DIR}/06-configmap.yaml" \
  -f "${MANIFEST_DIR}/07-service-postgres.yaml" \
  -f "${MANIFEST_DIR}/08-statefulset.yaml"
k rollout status statefulset/postgres-db --timeout=240s
k wait --for=jsonpath='{.status.phase}'=Bound \
  pvc/postgres-data-postgres-db-0 --timeout=90s
k exec postgres-db-0 -- \
  psql -U workshop -d workshop -c 'SELECT * FROM users;'

echo "OK: déploiement terminé dans ${WORKSHOP_NAMESPACE}."
