#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=scripts/_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

echo "[1/4] Garde-fous"
k apply -f "${MANIFEST_DIR}/02-guardrails.yaml"
k get limitrange,resourcequota

echo "[2/4] Frontend et Service"
k apply -f "${MANIFEST_DIR}/03-deployment.yaml" -f "${MANIFEST_DIR}/04-service.yaml"
k rollout status deployment/web-app --timeout=180s
web_pod="$(k get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')"
k exec "${web_pod}" -- wget -qO- --timeout=5 http://web-svc >/dev/null
echo "OK: deux réplicas Nginx et Service HTTP validés."

echo "[3/4] Libération des pods frontend pour la suite"
k scale deployment/web-app --replicas=0
k wait --for=delete pod -l app=frontend --timeout=120s

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
