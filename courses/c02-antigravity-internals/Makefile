.PHONY: test coverage pv gate

gate: test coverage pv

test:
	@set -eu; \
	dirs=0; passed=0; skipped=0; failed=0; \
	for d in examples/*/; do \
		[ -d "$$d" ] || continue; \
		dirs=$$((dirs + 1)); \
		ex=$${d%/}; \
		if [ ! -f "$${d}example.toml" ]; then \
			printf 'FAIL  %s  (missing example.toml)\n' "$$ex"; \
			failed=$$((failed + 1)); \
			continue; \
		fi; \
		set +e; \
		run_cmd=$$(awk 'BEGIN{in_ex=0;found=0} {line=$$0; sub(/^[ \t]+/,"",line); sub(/[ \t]+$$/,"",line); if(line==""||substr(line,1,1)=="#")next; if(line~/^\[example\]$$/){in_ex=1;next} if(line~/^\[/){in_ex=0;next} if(in_ex && line~/^run[ \t]*=/){p=index(line,"="); v=substr(line,p+1); sub(/^[ \t]+/,"",v); if(length(v)>=2 && substr(v,1,1)=="\"" && substr(v,length(v),1)=="\""){val=substr(v,2,length(v)-2); if(val!=""){print val;found=1;exit 0}} exit 2}} END{if(!found)exit 1}' "$${d}example.toml"); \
		parse_rc=$$?; \
		set -e; \
		if [ "$$parse_rc" -ne 0 ] || [ -z "$$run_cmd" ]; then \
			printf 'FAIL  %s  (missing or unsupported [example].run in example.toml)\n' "$$ex"; \
			failed=$$((failed + 1)); \
			continue; \
		fi; \
		is_live=0; \
		if printf '%s\n' "$$run_cmd" | grep -Eq '(^|[[:space:];|&])agy([[:space:]]|$$)'; then \
			is_live=1; \
		else \
			set -f; \
			for tok in $$run_cmd; do \
				case "$$tok" in \
					./*) \
						script=$${tok#./}; \
						if [ -f "$$d$$script" ] && grep -v '^[[:space:]]*#' "$$d$$script" | grep -Eq '(^|[[:space:];|&])agy([[:space:]]|$$)'; then \
							is_live=1; \
							break; \
						fi ;; \
				esac; \
			done; \
			set +f; \
		fi; \
		if [ "$$is_live" -eq 1 ]; then \
			printf 'SKIP(live)  %s  (%s)\n' "$$ex" "$$run_cmd"; \
			skipped=$$((skipped + 1)); \
			continue; \
		fi; \
		printf '==> %s: %s\n' "$$ex" "$$run_cmd"; \
		set +e; \
		(cd "$$d" && bash -c "$$run_cmd"); \
		rc=$$?; \
		set -e; \
		if [ "$$rc" -eq 0 ]; then \
			printf 'PASS  %s  (%s)\n' "$$ex" "$$run_cmd"; \
			passed=$$((passed + 1)); \
		else \
			printf 'FAIL  %s  (exit %d: %s)\n' "$$ex" "$$rc" "$$run_cmd"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$dirs" -eq 0 ]; then \
		echo "FAIL: anti-vacuity floor — no examples/*/ directories found" >&2; \
		exit 1; \
	fi; \
	printf 'test: %d passed, %d skipped (live), %d failed (%d total)\n' "$$passed" "$$skipped" "$$failed" "$$dirs"; \
	if [ "$$failed" -ne 0 ]; then \
		exit 1; \
	fi

coverage:
	@set -eu; \
	log=$$(mktemp); \
	trap 'rm -f "$$log"' EXIT; \
	set +e; \
	$(MAKE) --no-print-directory test >"$$log" 2>&1; \
	test_rc=$$?; \
	set -e; \
	cat "$$log"; \
	dirs=0; passed=0; skipped=0; bad=0; \
	for d in examples/*/; do \
		[ -d "$$d" ] || continue; \
		dirs=$$((dirs + 1)); \
		ex=$${d%/}; \
		state=$$(awk -v ex="$$ex" '($$1=="PASS"||$$1=="SKIP(live)"||$$1=="FAIL")&&$$2==ex{c++;s=$$1} END{if(c==0)print "MISSING";else if(c>1)print "DUPLICATE";else print s}' "$$log"); \
		case "$$state" in \
			PASS) passed=$$((passed + 1)) ;; \
			"SKIP(live)") skipped=$$((skipped + 1)) ;; \
			*) \
				printf 'FAIL: %s state in test output is [%s] (expected PASS or SKIP(live))\n' "$$ex" "$$state" >&2; \
				bad=$$((bad + 1)) ;; \
		esac; \
	done; \
	if [ "$$dirs" -eq 0 ]; then \
		echo "FAIL: anti-vacuity floor — no examples/*/ directories found" >&2; \
		exit 1; \
	fi; \
	printf 'coverage: %d PASS, %d SKIP(live), %d failed/uncovered (%d total)\n' "$$passed" "$$skipped" "$$bad" "$$dirs"; \
	if [ "$$bad" -ne 0 ] || [ "$$test_rc" -ne 0 ]; then \
		exit 1; \
	fi

PV_GATES := sigma shapes
pv:
	pv lint contracts
	@for g in $(PV_GATES); do \
	  if pv lint contracts --gate $$g --format json | grep -q '^  "verdict": "Pass"'; then \
	    echo "pv gate $$g: Pass"; else echo "pv gate $$g: FAIL"; exit 1; fi; \
	done
