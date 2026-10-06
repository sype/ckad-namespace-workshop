#!/usr/bin/env bash
set -uo pipefail

CLUSTER_NAME="${CKAD_CLUSTER_NAME:-ckad-local}"
failures=0

pass() { printf 'PASS %-20s %s\n' "$1" "$2"; }
fail() { printf 'FAIL %-20s %s\n' "$1" "$2"; failures=$((failures + 1)); }

for command in docker k3d kubectl; do
  if command -v "${command}" >/dev/null 2>&1; then
    pass "commande/${command}" "présente"
  else
    fail "commande/${command}" "absente"
  fi
done

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  pass docker "daemon accessible"
else
  fail docker "daemon inaccessible"
fi

k3d_version="$(k3d version 2>/dev/null | awk '/k3d version/ {sub(/^v/, "", $3); print $3}')"
if [[ "${k3d_version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] \
  && (( BASH_REMATCH[1] > 5 || (BASH_REMATCH[1] == 5 && BASH_REMATCH[2] >= 9) )); then
  pass k3d-version "${k3d_version} (minimum 5.9)"
else
  fail k3d-version "${k3d_version:-inconnue} (minimum 5.9)"
fi

kubectl_version="$(kubectl version --client 2>/dev/null | awk '/Client Version/ {sub(/^v/, "", $3); print $3}')"
if [[ "${kubectl_version}" =~ ^1\.([0-9]+)\. ]] \
  && (( BASH_REMATCH[1] >= 35 && BASH_REMATCH[1] <= 37 )); then
  pass kubectl-version "${kubectl_version} (supporté: 1.35 à 1.37)"
else
  fail kubectl-version "${kubectl_version:-inconnue} (supporté: 1.35 à 1.37)"
fi

if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -Fxq "${CLUSTER_NAME}"; then
  pass cluster "${CLUSTER_NAME} présent"
else
  fail cluster "${CLUSTER_NAME} absent"
fi

if [[ -z "${KUBECONFIG:-}" ]]; then
  fail kubeconfig "KUBECONFIG doit pointer vers le fichier dédié k3d"
elif [[ ! -f "${KUBECONFIG}" ]]; then
  fail kubeconfig "fichier introuvable"
else
  current_context="$(kubectl config current-context 2>/dev/null)"
  if [[ "${current_context}" == "k3d-${CLUSTER_NAME}" ]]; then
    pass kubeconfig "contexte ${current_context}"
  else
    fail kubeconfig "contexte inattendu: ${current_context:-aucun}"
  fi
fi

server_version="$(kubectl version 2>/dev/null | awk -F': ' '/Server Version/ {print $2}')"
if [[ "${server_version}" == v1.36.*+k3s1 ]]; then
  pass kubernetes "${server_version}"
else
  fail kubernetes "${server_version:-API inaccessible}; attendu v1.36.x+k3s1"
fi

ready_nodes="$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready" {count++} END {print count+0}')"
if [[ "${ready_nodes}" -eq 2 ]] 2>/dev/null; then
  pass nodes "2/2 Ready"
else
  fail nodes "${ready_nodes:-0}/2 Ready"
fi

if kubectl -n kube-system get deployment coredns \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null | grep -Eq '^[1-9][0-9]*$'; then
  pass dns "CoreDNS prêt"
else
  fail dns "CoreDNS indisponible"
fi

if kubectl get storageclass local-path \
  -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null \
  | grep -Fxq true; then
  pass storage "local-path par défaut"
else
  fail storage "StorageClass local-path par défaut absente"
fi

if (( failures > 0 )); then
  printf '\nDOCTOR=FAIL failures=%d\n' "${failures}"
  exit 1
fi

printf '\nDOCTOR=PASS cluster=%s trust=local_unverified\n' "${CLUSTER_NAME}"
