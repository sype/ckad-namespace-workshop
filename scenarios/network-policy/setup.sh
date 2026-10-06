#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"
k apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: api}
spec:
  replicas: 1
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
        - name: api
          image: busybox:1.37.0
          command: [sh, -c, "mkdir -p /www && echo CKAD-API >/www/index.html && httpd -f -p 8080 -h /www"]
          ports: [{name: http, containerPort: 8080}]
          readinessProbe: {tcpSocket: {port: http}}
          resources:
            requests: {cpu: 10m, memory: 16Mi}
            limits: {cpu: 50m, memory: 32Mi}
---
apiVersion: v1
kind: Service
metadata: {name: api}
spec:
  selector: {app: api}
  ports: [{name: http, port: 8080, targetPort: http}]
---
apiVersion: v1
kind: Pod
metadata: {name: client-allowed, labels: {role: client, access: api}}
spec:
  containers: [{name: client, image: busybox:1.37.0, command: [sleep, "3600"], resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {cpu: 50m, memory: 32Mi}}}]
---
apiVersion: v1
kind: Pod
metadata: {name: client-blocked, labels: {role: client, access: denied}}
spec:
  containers: [{name: client, image: busybox:1.37.0, command: [sleep, "3600"], resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {cpu: 50m, memory: 32Mi}}}]
YAML
k rollout status deployment/api --timeout=180s
k wait --for=condition=Ready pod/client-allowed pod/client-blocked --timeout=180s
echo "OK: workloads installés sans NetworkPolicy dans ${WORKSHOP_NAMESPACE}."
