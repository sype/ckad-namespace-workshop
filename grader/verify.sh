#!/usr/bin/env bash

set -uo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: WORKSHOP_NAMESPACE=<namespace> ./grader/verify.sh"
  echo "Calcule un score CKAD sur 100 sans afficher de Secret."
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"
# Le barème doit poursuivre les contrôles indépendants lorsqu'une ressource est
# absente. _common.sh active errexit pour les scripts opérationnels.
set +e

SCORE=0
PASSING_SCORE="${PASSING_SCORE:-80}"
TEST_TIMEOUT="${TEST_TIMEOUT:-120s}"
STATEFUL_PASS=false
NETWORK_ALLOW_PASS=false
NETWORK_DENY_PASS=false

award() {
  local id="$1" points="$2" message="$3"
  SCORE=$((SCORE + points))
  printf 'PASS %-18s +%3d  %s\n' "${id}" "${points}" "${message}"
}

miss() {
  local id="$1" points="$2" message="$3"
  printf 'FAIL %-18s +%3d  %s\n' "${id}" 0 "${message} (/${points})"
}

exists() {
  k get "$1" "$2" >/dev/null 2>&1
}

jsonpath() {
  k get "$1" "$2" -o "jsonpath=$3" 2>/dev/null
}

cleanup_test_pods() {
  k delete pod ckad-grade-frontend ckad-grade-backend \
    --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup_test_pods EXIT

echo "Évaluation du namespace ${WORKSHOP_NAMESPACE}"

if exists limitrange workshop-defaults && exists resourcequota workshop-quota &&
  [[ -n "$(jsonpath limitrange workshop-defaults '{.spec.limits[0].defaultRequest.cpu}')" ]] &&
  [[ -n "$(jsonpath limitrange workshop-defaults '{.spec.limits[0].default.memory}')" ]] &&
  [[ -n "$(jsonpath resourcequota workshop-quota '{.spec.hard.pods}')" ]] &&
  [[ -n "$(jsonpath resourcequota workshop-quota '{.spec.hard.requests\.storage}')" ]]; then
  award guardrails 15 "valeurs par défaut et quota détectés"
else
  miss guardrails 15 "LimitRange/ResourceQuota incomplets"
fi

frontend_selector="$(jsonpath deployment web-app '{.spec.selector.matchLabels.app}')"
frontend_template="$(jsonpath deployment web-app '{.spec.template.metadata.labels.app}')"
service_selector="$(jsonpath service web-svc '{.spec.selector.app}')"
service_port="$(jsonpath service web-svc '{.spec.ports[0].port}')"
if [[ "${frontend_selector}" == "frontend" ]] &&
  [[ "${frontend_template}" == "frontend" ]] &&
  [[ "${service_selector}" == "frontend" ]] && [[ "${service_port}" == "80" ]]; then
  award frontend 15 "Deployment et Service correctement reliés"
else
  miss frontend 15 "sélecteurs frontend ou Service incorrects"
fi

db_ready="$(jsonpath statefulset postgres-db '{.status.readyReplicas}')"
pvc_phase="$(jsonpath pvc postgres-data-postgres-db-0 '{.status.phase}')"
db_rows=""
if [[ "${db_ready:-0}" -ge 1 ]] 2>/dev/null; then
  db_rows="$(k exec postgres-db-0 -- psql -U workshop -d workshop -Atc \
    'SELECT name FROM users ORDER BY id;' 2>/dev/null || true)"
fi
if [[ "${db_ready:-0}" -ge 1 ]] 2>/dev/null &&
  [[ "$(jsonpath service postgres-svc '{.spec.clusterIP}')" == "None" ]] &&
  [[ "${pvc_phase}" == "Bound" ]] && [[ "${db_rows}" == $'Alice\nBob' ]]; then
  award stateful 25 "StatefulSet, Service headless, PVC et données valides"
  STATEFUL_PASS=true
else
  miss stateful 25 "chaîne stateful incomplète"
fi

if [[ "${db_rows}" == $'Alice\nBob' ]] &&
  k delete pod postgres-db-0 --wait=true --timeout="${TEST_TIMEOUT}" >/dev/null 2>&1 &&
  k wait --for=condition=Ready pod/postgres-db-0 --timeout="${TEST_TIMEOUT}" >/dev/null 2>&1 &&
  [[ "$(k exec postgres-db-0 -- psql -U workshop -d workshop -Atc \
    'SELECT name FROM users ORDER BY id;' 2>/dev/null || true)" == $'Alice\nBob' ]]; then
  award persistence 15 "données conservées après recréation du Pod"
else
  miss persistence 15 "persistance non démontrée"
fi

probe_and_resources=true
for ref in 'deployment/web-app' 'statefulset/postgres-db'; do
  [[ -n "$(k get "${ref}" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)" ]] || probe_and_resources=false
  [[ -n "$(k get "${ref}" -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)" ]] || probe_and_resources=false
  [[ -n "$(k get "${ref}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)" ]] || probe_and_resources=false
done
if [[ "${probe_and_resources}" == true ]]; then
  award probes-resources 10 "readiness probes et ressources explicites"
else
  miss probes-resources 10 "probe ou resources manquantes"
fi

network_policy_ready=false
if exists networkpolicy db-network-policy && [[ "${db_ready:-0}" -ge 1 ]] 2>/dev/null; then
  network_policy_ready=true
fi

if [[ "${network_policy_ready}" == true ]] &&
  k run ckad-grade-frontend --image=busybox:1.37.0 --restart=Never \
    --labels='app=frontend,tier=web' --command -- sleep 300 >/dev/null 2>&1 &&
  k wait --for=condition=Ready pod/ckad-grade-frontend --timeout="${TEST_TIMEOUT}" >/dev/null 2>&1 &&
  k exec ckad-grade-frontend -- nc -z -w 5 postgres-svc 5432 >/dev/null 2>&1; then
  award network-allow 10 "frontend autorisé sur TCP/5432"
  NETWORK_ALLOW_PASS=true
else
  miss network-allow 10 "test frontend refusé ou indisponible"
fi
k delete pod ckad-grade-frontend --ignore-not-found --wait=true >/dev/null 2>&1 || true

if [[ "${network_policy_ready}" == true ]] &&
  k run ckad-grade-backend --image=busybox:1.37.0 --restart=Never \
    --labels='app=backend,tier=api' --command -- sleep 300 >/dev/null 2>&1 &&
  k wait --for=condition=Ready pod/ckad-grade-backend --timeout="${TEST_TIMEOUT}" >/dev/null 2>&1; then
  if k exec ckad-grade-backend -- nc -z -w 5 postgres-svc 5432 >/dev/null 2>&1; then
    miss network-deny 10 "le backend atteint encore PostgreSQL"
  else
    award network-deny 10 "backend refusé sur TCP/5432"
    NETWORK_DENY_PASS=true
  fi
else
  miss network-deny 10 "test backend indisponible"
fi

trap - EXIT
cleanup_test_pods
RESULT=FAIL
if [[ "${SCORE}" -ge "${PASSING_SCORE}" ]] &&
  [[ "${STATEFUL_PASS}" == true ]] &&
  [[ "${NETWORK_ALLOW_PASS}" == true ]] &&
  [[ "${NETWORK_DENY_PASS}" == true ]]; then
  RESULT=PASS
fi
printf '\nSCORE=%d/100 PASSING_SCORE=%d REQUIRED=stateful,network-allow,network-deny RESULT=%s\n' \
  "${SCORE}" "${PASSING_SCORE}" "${RESULT}"

[[ "${RESULT}" == PASS ]]
