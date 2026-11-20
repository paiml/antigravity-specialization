.PHONY: gate coverage
gate: ## Everything CI runs on a pull request: the gate, then 100% line coverage
	scripts/gate.sh
	scripts/coverage.sh
coverage: ## 100% line coverage, every module
	scripts/coverage.sh
