#!/usr/bin/env bash
set -uo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"
set +e

score=0; default_pass=false; dns_pass=false; policy_pass=false; allow_pass=false; deny_pass=false
award() { score=$((score + $1)); printf 'PASS %-18s +%3d  %s\n' "$2" "$1" "$3"; }
miss() { printf 'FAIL %-18s +%3d  %s\n' "$2" 0 "$3"; }
default_types="$(k get networkpolicy default-deny -o jsonpath='{.spec.policyTypes[*]}' 2>/dev/null)"
default_selector="$(k get networkpolicy default-deny -o jsonpath='{.spec.podSelector}' 2>/dev/null)"
if [[ " ${default_types} " == *" Ingress "* && " ${default_types} " == *" Egress "* ]] \
  && [[ "${default_selector}" == 'map[]' || "${default_selector}" == '{}' ]]; then
  award 20 default-deny "ingress et egress isolés"; default_pass=true
else miss 20 default-deny "policy default-deny incomplète"; fi

dns_namespace="$(k get networkpolicy allow-dns -o jsonpath='{.spec.egress[*].to[*].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}' 2>/dev/null)"
dns_ports="$(k get networkpolicy allow-dns -o jsonpath='{range .spec.egress[*].ports[*]}{.protocol}:{.port}{" "}{end}' 2>/dev/null)"
if [[ "${dns_namespace}" == kube-system && " ${dns_ports} " == *" UDP:53 "* && " ${dns_ports} " == *" TCP:53 "* ]]; then
  award 20 dns-egress "DNS UDP/TCP explicitement autorisé"; dns_pass=true
else miss 20 dns-egress "allow-dns doit viser kube-system UDP/TCP 53"; fi

ingress_target="$(k get networkpolicy allow-api -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)"
ingress_source="$(k get networkpolicy allow-api -o jsonpath='{.spec.ingress[*].from[*].podSelector.matchLabels.access}' 2>/dev/null)"
ingress_ports="$(k get networkpolicy allow-api -o jsonpath='{range .spec.ingress[*].ports[*]}{.protocol}:{.port}{" "}{end}' 2>/dev/null)"
egress_source="$(k get networkpolicy allow-api-client-egress -o jsonpath='{.spec.podSelector.matchLabels.access}' 2>/dev/null)"
egress_target="$(k get networkpolicy allow-api-client-egress -o jsonpath='{.spec.egress[*].to[*].podSelector.matchLabels.app}' 2>/dev/null)"
egress_ports="$(k get networkpolicy allow-api-client-egress -o jsonpath='{range .spec.egress[*].ports[*]}{.protocol}:{.port}{" "}{end}' 2>/dev/null)"
if [[ "${ingress_target}" == api && "${ingress_source}" == api && " ${ingress_ports} " == *" TCP:8080 "* \
  && "${egress_source}" == api && "${egress_target}" == api && " ${egress_ports} " == *" TCP:8080 "* ]]; then
  award 20 least-privilege "seul access=api vise app=api:8080"; policy_pass=true
else miss 20 least-privilege "policies ingress/egress minimales requises"; fi

allowed_ready="$(k get pod client-allowed -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
blocked_ready="$(k get pod client-blocked -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [[ "${allowed_ready}" == True ]] && k exec client-allowed -- wget -qO- -T 5 http://api:8080 2>/dev/null | grep -q CKAD-API; then
  award 20 allowed-runtime "client-allowed atteint api"; allow_pass=true
else miss 20 allowed-runtime "flux autorisé indisponible"; fi

if [[ "${blocked_ready}" == True && "${allow_pass}" == true ]]; then
  k exec client-blocked -- wget -qO- -T 5 http://api:8080 >/dev/null 2>&1
  rc=$?
  if [[ "${rc}" -ne 0 ]]; then award 20 denied-runtime "client-blocked refusé"; deny_pass=true; else miss 20 denied-runtime "client-blocked atteint encore api"; fi
else miss 20 denied-runtime "client bloqué indisponible ou contrôle positif en échec"; fi

result=FAIL
if [[ "${score}" -ge 80 && "${default_pass}" == true && "${dns_pass}" == true && "${policy_pass}" == true && "${allow_pass}" == true && "${deny_pass}" == true ]]; then result=PASS; fi
printf '\nSCORE=%d/100 TRUST=local_unverified RESULT=%s\n' "${score}" "${result}"
[[ "${result}" == PASS ]]
