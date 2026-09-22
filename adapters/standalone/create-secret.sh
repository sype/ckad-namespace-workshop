#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"

command -v openssl >/dev/null 2>&1 || {
  echo "Erreur: openssl est nécessaire." >&2
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
echo "OK: db-secret créé ou mis à jour sans écrire sa valeur sur disque."
