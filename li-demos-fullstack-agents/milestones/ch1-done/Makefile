SHELL := bash
.PHONY: test lint run smoke ci

test:
	node --test

lint:
	scripts/lint.sh

run:
	node main.js

smoke:
	scripts/smoke.sh

ci: lint test
