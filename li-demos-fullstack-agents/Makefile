SHELL := bash
.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: gate gate-lint gate-test gate-nopython gate-secrets gate-leaks gate-coverage gate-js gate-contract

# gate: what CI runs. No model, no network and no browser are needed.
gate: gate-nopython gate-lint gate-test gate-js gate-leaks gate-coverage gate-contract

gate-nopython:
	@scripts/gate-nopython.sh

gate-lint:
	@scripts/gate-lint.sh

gate-test:
	@tests/run-tests.sh

# gate-js: every milestone's node tests, and 100% line coverage of the finished app.
gate-js:
	@scripts/gate-js.sh

# gate-leaks: grep-based scan for key patterns, internal paths and hostnames. NOT gitleaks.
gate-leaks:
	@scripts/gate-leaks.sh

# gate-coverage: line coverage of the demo shell code by the offline tests (xtrace based). Measured 94.6%; the floor is 94, not 100: the missed lines are failure branches and the docker-pull-failure path.
gate-coverage:
	@scripts/coverage-trace.sh 94

# gate-contract: validate the contract file with pv.
gate-contract:
	@scripts/gate-contract.sh

# gate-secrets needs the gitleaks binary (CI installs a pinned one).
gate-secrets:
	gitleaks detect --source . --config .gitleaks.toml --no-banner
