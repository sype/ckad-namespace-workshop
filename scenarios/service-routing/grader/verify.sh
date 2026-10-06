#!/usr/bin/env bash
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"
set +e

score=0; endpoints_pass=false; dns_pass=false; http_pass=false
award() { score=$((score + $1)); printf 'PASS %-18s +%3d  %s\n' "$2" "$1" "$3"; }
miss() { printf 'FAIL %-18s +%3d  %s\n' "$2" 0 "$3"; }
cleanup() { k delete pod ckad-service-probe --ignore-not-found --wait=true --timeout=60s >/dev/null 2>&1 || true; }
trap cleanup EXIT

ready="$(k get deployment catalog -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
if [[ "${ready:-0}" -eq 2 ]] 2>/dev/null; then award 20 workload "deux Pods prêts"; else miss 20 workload "deux Pods prêts requis"; fi

selector_app="$(k get service catalog -o jsonpath='{.spec.selector.app}' 2>/dev/null)"
selector_tier="$(k get service catalog -o jsonpath='{.spec.selector.tier}' 2>/dev/null)"
port="$(k get service catalog -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)"
target="$(k get service catalog -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null)"
if [[ "${selector_app}" == catalog && "${selector_tier}" == api && "${port}" == 80 && "${target}" == http ]]; then
  award 25 service-contract "selector et ports corrects"
else miss 25 service-contract "selector app=catalog,tier=api et 80->http requis"; fi

endpoint_count="$(k get endpointslice -l kubernetes.io/service-name=catalog \
  -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | awk 'NF {n++} END {print n+0}')"
if [[ "${endpoint_count:-0}" -ge 2 ]] 2>/dev/null; then award 25 endpoints "${endpoint_count} endpoints prêts"; endpoints_pass=true; else miss 25 endpoints "au moins deux endpoints prêts requis"; fi

cleanup
if k run ckad-service-probe --image=busybox:1.37.0 --restart=Never --command -- sleep 300 >/dev/null 2>&1 \
  && k wait --for=condition=Ready pod/ckad-service-probe --timeout=120s >/dev/null 2>&1; then
  dns_output="$(k exec ckad-service-probe -- nslookup catalog 2>&1 || true)"
  if grep -Eq '(^|[[:space:]])Name:[[:space:]]+catalog([[:space:].]|$)' <<<"${dns_output}"; then award 15 dns "catalog résolu"; dns_pass=true; else miss 15 dns "résolution impossible"; fi
  if k exec ckad-service-probe -- wget -qO- -T 5 http://catalog >/dev/null 2>&1; then award 15 http "Service HTTP accessible"; http_pass=true; else miss 15 http "Service HTTP inaccessible"; fi
else
  miss 15 dns "Pod de sonde indisponible"; miss 15 http "Pod de sonde indisponible"
fi

result=FAIL
if [[ "${score}" -ge 80 && "${endpoints_pass}" == true && "${dns_pass}" == true && "${http_pass}" == true ]]; then result=PASS; fi
printf '\nSCORE=%d/100 TRUST=local_unverified RESULT=%s\n' "${score}" "${result}"
[[ "${result}" == PASS ]]
