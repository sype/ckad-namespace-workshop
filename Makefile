.PHONY: preflight deploy test cleanup validate

preflight:
	./scripts/preflight.sh

deploy:
	./scripts/deploy.sh

test:
	./scripts/test.sh

cleanup:
	./scripts/cleanup.sh

validate:
	bash -n scripts/*.sh
	for file in manifests/*.yaml; do ruby -e 'require "yaml"; YAML.load_stream(File.read(ARGV[0]))' "$$file"; done
