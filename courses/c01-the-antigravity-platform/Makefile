SHELL := /bin/bash

.PHONY: test coverage pv gate

gate: test coverage pv

test:
	@set -euo pipefail; \
	toml_get() { \
		awk -v key="$$1" '{ \
			line = $$0; \
			sub(/^[ \t]+/, "", line); sub(/[ \t]+$$/, "", line); \
			if (line == "" || substr(line, 1, 1) == "#") next; \
			if (line ~ /^\[[A-Za-z0-9_]+\]$$/) { sect = substr(line, 2, length(line) - 2); next } \
			if (line ~ /^\[\[/) { sect = ""; next } \
			if (sect != "example") next; \
			p = index(line, "="); \
			if (p == 0) next; \
			k = substr(line, 1, p - 1); sub(/[ \t]+$$/, "", k); \
			if (k != key) next; \
			v = substr(line, p + 1); sub(/^[ \t]+/, "", v); \
			if (length(v) >= 2 && substr(v, 1, 1) == "\"" && substr(v, length(v), 1) == "\"") { \
				val = substr(v, 2, length(v) - 2); \
				if (index(val, "\\") > 0 || index(val, "\"") > 0) exit 2; \
				print val; found = 1; exit 0; \
			} \
			exit 2; \
		} END { if (!found) exit 1 }' "$$2"; \
	}; \
	total=0; passed=0; skipped=0; failed=0; \
	skipped_list=(); \
	for raw in examples/*/; do \
		[ -d "$$raw" ] || continue; \
		dir="$${raw%/}"; \
		total=$$((total + 1)); \
		toml="$$dir/example.toml"; \
		if [ ! -f "$$toml" ]; then \
			echo "FAIL $$dir"; \
			echo "  reason: missing example.toml" >&2; \
			failed=$$((failed + 1)); \
			continue; \
		fi; \
		if ! run_cmd=$$(toml_get run "$$toml") || [ -z "$$run_cmd" ]; then \
			echo "FAIL $$dir"; \
			echo "  reason: missing or invalid [example].run in $$toml" >&2; \
			failed=$$((failed + 1)); \
			continue; \
		fi; \
		req_rc=0; \
		req=$$(toml_get requires "$$toml") || req_rc=$$?; \
		if [ "$$req_rc" -eq 2 ]; then \
			echo "FAIL $$dir"; \
			echo "  reason: invalid [example].requires in $$toml" >&2; \
			failed=$$((failed + 1)); \
			continue; \
		fi; \
		if [ "$${LIVE:-0}" != "1" ] && { \
			printf '%s\n' "$$run_cmd" | grep -Eq '(^|[[:space:]&|;])agy([[:space:]]|$$)' || \
			printf '%s\n' "$$req" | grep -Eq '(^Requires the Antigravity CLI|does not run headless|interactive)'; \
		}; then \
			echo "SKIP(live) $$dir"; \
			skipped=$$((skipped + 1)); \
			skipped_list+=("$$dir"); \
			continue; \
		fi; \
		echo "==> test: $$dir ($$run_cmd)"; \
		if (cd "$$dir" && bash -c "$$run_cmd"); then \
			echo "PASS $$dir"; \
			passed=$$((passed + 1)); \
		else \
			echo "FAIL $$dir"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$total" -eq 0 ]; then \
		echo "FAIL: anti-vacuity check — no examples/*/ directories found" >&2; \
		exit 1; \
	fi; \
	if [ "$${#skipped_list[@]}" -gt 0 ]; then \
		echo "SKIP(live) examples (not counted as passed): $${skipped_list[*]}"; \
	fi; \
	echo "Summary: passed=$$passed skipped_live=$$skipped failed=$$failed total=$$total"; \
	if [ "$$failed" -ne 0 ]; then \
		echo "FAIL: $$failed of $$total example(s) failed" >&2; \
		exit 1; \
	fi

coverage:
	@set -euo pipefail; \
	total=0; passed=0; skipped=0; uncovered=0; \
	log=$$(mktemp); \
	trap 'rm -f "$$log"' EXIT; \
	set +e; \
	$(MAKE) --no-print-directory test >"$$log" 2>&1; \
	test_rc=$$?; \
	set -e; \
	cat "$$log"; \
	for raw in examples/*/; do \
		[ -d "$$raw" ] || continue; \
		dir="$${raw%/}"; \
		total=$$((total + 1)); \
		is_pass=0; is_skip=0; is_fail=0; \
		if grep -Fqx "PASS $$dir" "$$log"; then is_pass=1; fi; \
		if grep -Fqx "SKIP(live) $$dir" "$$log"; then is_skip=1; fi; \
		if grep -Fqx "FAIL $$dir" "$$log"; then is_fail=1; fi; \
		if [ "$$is_fail" -eq 0 ] && [ "$$is_pass" -eq 1 ] && [ "$$is_skip" -eq 0 ]; then \
			passed=$$((passed + 1)); \
		elif [ "$$is_fail" -eq 0 ] && [ "$$is_skip" -eq 1 ] && [ "$$is_pass" -eq 0 ]; then \
			skipped=$$((skipped + 1)); \
		else \
			echo "FAIL: $$dir did not appear strictly as PASS or SKIP(live) in test output" >&2; \
			uncovered=$$((uncovered + 1)); \
		fi; \
	done; \
	if [ "$$total" -eq 0 ]; then \
		echo "FAIL: anti-vacuity check — no examples/*/ directories found" >&2; \
		exit 1; \
	fi; \
	echo "Coverage: $$((passed + skipped))/$$total example(s) accounted for (pass=$$passed, skip_live=$$skipped, uncovered=$$uncovered)"; \
	if [ "$$test_rc" -ne 0 ] || [ "$$uncovered" -ne 0 ]; then \
		exit 1; \
	fi

# Provable contracts and the pv ontology (pv = aprender-contracts-cli, on PATH; never installed here).
# `pv lint` prints PASS even when one gate fails, so each ontology gate's verdict is read on its own.
PV_GATES := sigma shapes
pv:
	@for g in $(PV_GATES); do \
	  if pv lint contracts --gate $$g --format json | grep -q '^  "verdict": "Pass"'; then \
	    echo "pv gate $$g: Pass"; else echo "pv gate $$g: FAIL"; exit 1; fi; \
	done
