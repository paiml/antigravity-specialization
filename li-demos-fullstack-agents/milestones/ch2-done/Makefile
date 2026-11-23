SHELL := bash
.PHONY: test cover lint run smoke ci

test:
	node --test

# cover: node's built-in line coverage, 100% required on server, db and the page scripts.
cover:
	node --test --experimental-test-coverage --test-coverage-lines=100 \
	  --test-coverage-exclude='testlib/**' --test-coverage-exclude='test/**' --test-coverage-exclude='main.js'

lint:
	scripts/lint.sh

run:
	node main.js

smoke:
	scripts/smoke.sh

ci: lint test
