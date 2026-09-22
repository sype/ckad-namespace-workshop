#!/usr/bin/env bash

set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

bash -n scripts/*.sh adapters/standalone/*.sh \
  adapters/educates/workshop/setup.d/*.sh grader/*.sh grader/tests/*.sh tests/*.sh

required=(curriculum student solution grader adapters/standalone adapters/educates)
for path in "${required[@]}"; do
  [[ -e "${path}" ]] || { echo "Chemin requis absent: ${path}" >&2; exit 1; }
done

rubric_total="$(ruby -e '
require "yaml"
data = YAML.safe_load(File.read("curriculum/rubric.yaml"), aliases: false)
puts data.fetch("spec").fetch("checks").sum { |check| check.fetch("points") }
')"
[[ "${rubric_total}" == "100" ]] || {
  echo "Le barème vaut ${rubric_total}, attendu: 100." >&2
  exit 1
}

if find . -type f \( -name '*.kubeconfig' -o -name '.env' -o -name 'kubeconfig*' \) | grep -q .; then
  echo "Fichier sensible détecté." >&2
  exit 1
fi

if git grep -nE '(client-key-data:|token: +eyJ|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' -- \
  ':!.github/workflows/validate.yml' ':!tests/static.sh'; then
  echo "Marqueur de credential détecté." >&2
  exit 1
fi

echo "OK: structure, scripts, barème et garde-fous statiques validés."
"${ROOT_DIR}/grader/tests/test-missing-resources.sh"
