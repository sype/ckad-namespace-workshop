#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/_common.sh
source "${ROOT_DIR}/scripts/_common.sh"
k delete deployment/api service/api pod/client-allowed pod/client-blocked networkpolicy/default-deny networkpolicy/allow-dns networkpolicy/allow-api networkpolicy/allow-api-client-egress --ignore-not-found --wait=false
