#!/usr/bin/env bash

set -Eeuo pipefail
# shellcheck source=scripts/_common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"

cleanup_test_pods() {
  k delete pod test-frontend test-backend --ignore-not-found --wait=true >/dev/null 2>&1 || true
}
trap cleanup_test_pods EXIT

echo "[1/3] Persistance après recréation du pod"
k delete pod postgres-db-0 --wait=true
k wait --for=condition=Ready pod/postgres-db-0 --timeout=240s
query_output="$(k exec postgres-db-0 -- \
  psql -U workshop -d workshop -Atc 'SELECT name FROM users ORDER BY id;')"
if [[ "${query_output}" != $'Alice\nBob' ]]; then
  echo "Erreur: les données attendues ne sont pas présentes." >&2
  exit 4
fi

echo "[2/3] Flux frontend autorisé"
k apply -f "${MANIFEST_DIR}/09-networkpolicy.yaml"
k apply -f "${MANIFEST_DIR}/10-test-frontend.yaml"
k wait --for=condition=Ready pod/test-frontend --timeout=180s
k exec test-frontend -- nc -z -w 5 postgres-svc 5432
k delete pod test-frontend --wait=true

echo "[3/3] Flux backend refusé"
k apply -f "${MANIFEST_DIR}/11-test-backend.yaml"
k wait --for=condition=Ready pod/test-backend --timeout=180s
if k exec test-backend -- nc -z -w 5 postgres-svc 5432; then
  echo "Erreur: le backend atteint PostgreSQL malgré la NetworkPolicy." >&2
  exit 5
fi
k delete pod test-backend --wait=true
trap - EXIT

echo "OK: persistance et NetworkPolicy validées."
