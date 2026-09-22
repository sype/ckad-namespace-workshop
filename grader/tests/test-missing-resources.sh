#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if output="$(KUBECTL_BIN="${ROOT_DIR}/grader/tests/fake-kubectl.sh" \
  TEST_TIMEOUT=1s "${ROOT_DIR}/grader/verify.sh" 2>&1)"; then
  echo "Le grader devait échouer sous le seuil." >&2
  exit 1
fi

grep -q 'SCORE=0/100' <<<"${output}" || {
  echo "Score inattendu lorsque toutes les ressources manquent." >&2
  echo "${output}" >&2
  exit 1
}

echo "OK: le grader produit un score partiel même sans ressources."
