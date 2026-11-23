SHELL := bash
.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: gate gate-lint gate-test gate-nopython gate-secrets gate-leaks gate-coverage

# gate: what CI runs. No model and no network are needed.
gate: gate-nopython gate-lint gate-test gate-leaks gate-coverage

gate-nopython:
	@scripts/gate-nopython.sh

gate-lint:
	@scripts/gate-lint.sh

gate-test:
	@tests/run-tests.sh

# gate-leaks: grep-based scan for key patterns, internal paths and hostnames. NOT gitleaks.
gate-leaks:
	@scripts/gate-leaks.sh

# gate-coverage: line coverage of the shell code by the offline tests (xtrace based), must be 100%.
gate-coverage:
	@scripts/coverage-trace.sh 100

# gate-secrets needs the gitleaks binary (CI installs a pinned one).
gate-secrets:
	gitleaks detect --source . --config .gitleaks.toml --no-banner
