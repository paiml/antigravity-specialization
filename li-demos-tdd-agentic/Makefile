SHELL := bash
.SUFFIXES:
.DELETE_ON_ERROR:
.PHONY: gate gate-nopython gate-lint gate-scan gate-test coverage pv

# gate: what CI runs. No agent, no login and no network are needed.
gate: gate-nopython gate-lint gate-scan gate-test

gate-nopython:
	@scripts/gate-nopython.sh

gate-lint:
	@scripts/gate-lint.sh

gate-scan:
	@scripts/gate-scan.sh

gate-test:
	@tests/run-tests.sh

# coverage: line coverage of the shell code, from bash xtrace (an approximation, lines not branches).
coverage:
	@scripts/coverage.sh

# pv: validate the formal contract (needs the pv binary).
pv:
	pv validate contracts/slugify-v1.yaml
