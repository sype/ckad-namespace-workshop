#!/usr/bin/env bash

set -Eeuo pipefail

namespace="$(kubectl config view --minify -o jsonpath='{..namespace}')"
case "${namespace}" in
  ""|default|kube-system|kube-public|kube-node-lease)
    echo "Namespace de session invalide." >&2
    exit 2
    ;;
esac

db_password="$(openssl rand -hex 24)"
kubectl -n "${namespace}" create secret generic db-secret \
  --from-literal=username=workshop \
  --from-literal=database=workshop \
  --from-literal=password="${db_password}" \
  --dry-run=client -o yaml | kubectl -n "${namespace}" apply -f -
unset db_password
