#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"

k apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
spec:
  replicas: 2
  selector:
    matchLabels: {app: catalog, tier: api}
  template:
    metadata:
      labels: {app: catalog, tier: api}
    spec:
      containers:
        - name: web
          image: nginx:1.27.5-alpine
          ports:
            - name: http
              containerPort: 80
          readinessProbe:
            httpGet: {path: /, port: http}
          resources:
            requests: {cpu: 20m, memory: 32Mi}
            limits: {cpu: 100m, memory: 64Mi}
---
apiVersion: v1
kind: Service
metadata:
  name: catalog
spec:
  selector: {app: catalogue, tier: api}
  ports:
    - name: http
      port: 80
      targetPort: web
YAML
k rollout status deployment/catalog --timeout=180s
echo "OK: état cassé installé dans ${WORKSHOP_NAMESPACE}."
