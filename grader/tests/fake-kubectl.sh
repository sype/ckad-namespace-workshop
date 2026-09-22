#!/usr/bin/env bash

set -u

if [[ "${1:-}" == "config" && "${2:-}" == "current-context" ]]; then
  echo "test-context"
  exit 0
fi
if [[ "${1:-}" == "config" && "${2:-}" == "view" ]]; then
  echo "ckad-test"
  exit 0
fi

if [[ "${1:-}" == "-n" ]]; then
  shift 2
fi

case "${1:-}" in
  delete) exit 0 ;;
  *) exit 1 ;;
esac
