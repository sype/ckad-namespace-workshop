#!/usr/bin/env bash
set -Eeuo pipefail

CLUSTER_NAME="${CKAD_CLUSTER_NAME:-ckad-local}"
K3S_IMAGE="${CKAD_K3S_IMAGE:-rancher/k3s:v1.36.4-k3s1}"

for command in docker k3d kubectl; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "ERREUR: ${command} est requis." >&2
    exit 1
  fi
done

k3d_version="$(k3d version 2>/dev/null | awk '/k3d version/ {sub(/^v/, "", $3); print $3}')"
if [[ ! "${k3d_version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] \
  || (( BASH_REMATCH[1] < 5 || (BASH_REMATCH[1] == 5 && BASH_REMATCH[2] < 9) )); then
  echo "ERREUR: k3d 5.9 ou supérieur est requis (détecté: ${k3d_version:-inconnu})." >&2
  exit 1
fi

kubectl_version="$(kubectl version --client 2>/dev/null | awk '/Client Version/ {sub(/^v/, "", $3); print $3}')"
if [[ ! "${kubectl_version}" =~ ^1\.([0-9]+)\. ]] \
  || (( BASH_REMATCH[1] < 35 || BASH_REMATCH[1] > 37 )); then
  echo "ERREUR: kubectl 1.35 à 1.37 est requis (détecté: ${kubectl_version:-inconnu})." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERREUR: Docker n'est pas disponible. Démarrez Docker Desktop." >&2
  exit 1
fi

if k3d cluster list --no-headers 2>/dev/null | awk '{print $1}' | grep -Fxq "${CLUSTER_NAME}"; then
  echo "ERREUR: le cluster ${CLUSTER_NAME} existe déjà." >&2
  echo "Utilisez ./adapters/local/doctor.sh ou supprimez-le explicitement avec :" >&2
  echo "k3d cluster delete ${CLUSTER_NAME}" >&2
  exit 1
fi

k3d cluster create "${CLUSTER_NAME}" \
  --image "${K3S_IMAGE}" \
  --servers 1 \
  --agents 1 \
  --wait \
  --timeout 5m \
  --kubeconfig-update-default=false

kubeconfig_path="$(k3d kubeconfig write "${CLUSTER_NAME}")"
KUBECONFIG="${kubeconfig_path}" kubectl wait \
  --for=condition=Ready nodes --all --timeout=180s

cat <<EOF

Cluster ${CLUSTER_NAME} prêt.
Le contexte Kubernetes par défaut n'a pas été modifié.

Dans ce terminal, exécutez :
  export KUBECONFIG="${kubeconfig_path}"
  ./adapters/local/doctor.sh
EOF
