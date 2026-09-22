.PHONY: preflight deploy test grade cleanup validate

preflight:
	./scripts/preflight.sh

deploy:
	./scripts/deploy.sh

test:
	./scripts/test.sh

grade:
	./grader/verify.sh

cleanup:
	./scripts/cleanup.sh

validate:
	./tests/static.sh
	for file in $$(find . -type f \( -name '*.yaml' -o -name '*.yml' \)); do ruby -e 'require "yaml"; YAML.load_stream(File.read(ARGV[0]))' "$$file"; done
