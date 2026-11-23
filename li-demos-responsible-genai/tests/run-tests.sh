#!/usr/bin/env bash
# Offline tests: no model, no network. DEMO_STUB replaces the server with a canned reply.
# Each test can fail: the last block flips an input and requires the check to go red.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
. "$root/lib/common.sh"
work="$root/.run/test"
mkdir -p "$work"
pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok    $1"; }
no() { fail=$((fail + 1)); echo "FAIL  $1"; }
expect_eq() { if [ "$2" = "$3" ]; then ok "$1"; else no "$1 (got '$2', want '$3')"; fi; }
expect_rc() { # name want_rc cmd...
  local name="$1" want="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local rc=$?
  if [ "$rc" -eq "$want" ]; then ok "$name"; else no "$name (rc $rc, want $want)"; fi
}

# redact
expect_eq "redact masks an api key" "$(echo 'k sk-ABCDEFGHIJKLMNOP1234' | redact)" "k [REDACTED-KEY]"
expect_eq "redact masks an email" "$(echo 'a@b.com' | redact)" "[REDACTED-EMAIL]"
expect_eq "redact masks an ssn" "$(echo 'id 123-45-6789' | redact)" "id [REDACTED-SSN]"
expect_eq "redact leaves clean text alone" "$(echo 'hello world' | redact)" "hello world"

# sensitivity
expect_eq "sensitivity high for patient" "$(sensitivity 'patient notes')" "high"
expect_eq "sensitivity low for blog" "$(sensitivity 'public blog post')" "low"

# audit chain
log="$work/audit.jsonl"
: >"$log"
audit_append "$log" one
audit_append "$log" two
audit_append "$log" three
expect_rc "audit chain verifies" 0 audit_verify "$log"
sed '2s/two/TWO/' "$log" >"$work/t.jsonl"
expect_rc "audit chain: edit of a middle line breaks the chain" 1 audit_verify "$work/t.jsonl"
sed '1s/one/ONE/' "$log" >"$work/t1.jsonl"
expect_rc "audit chain: edit of line 1 breaks the chain" 1 audit_verify "$work/t1.jsonl"

# JSON lesson with a stub reply
printf '{"name":"A","age":3,"city":"B","role":"C"}' >"$work/good.json"
printf 'not json at all' >"$work/bad.json"
expect_rc "json lesson accepts valid JSON" 0 env DEMO_STUB="$work/good.json" "$root/c2l5-json-validate/run.sh"
expect_rc "json lesson rejects invalid JSON" 1 env DEMO_STUB="$work/bad.json" "$root/c2l5-json-validate/run.sh"

# ship gate (lesson 4.1) with a stub: every answer is "Paris", so only 1 of 5 passes and the 60% gate must fail
printf 'Paris' >"$work/paris.txt"
expect_rc "eval gate fails a weak model" 1 env DEMO_STUB="$work/paris.txt" "$root/c4l1-eval-set/run.sh"
expect_rc "eval gate passes when threshold is 20" 0 env THRESHOLD=20 DEMO_STUB="$work/paris.txt" "$root/c4l1-eval-set/run.sh"

# secrets lesson: no leak after redaction
expect_rc "secrets lesson passes leak check" 0 env DEMO_NO_MODEL=1 "$root/c3l4-secrets/run.sh"

# guardrails: log must hold no raw ssn
expect_rc "guardrails run with stub" 0 env DEMO_STUB="$work/paris.txt" "$root/c3l6-guardrails/run.sh"
if grep -q '123-45-6789' "$root/c3l6-guardrails/guard.log.jsonl"; then no "guard log holds no raw ssn"; else ok "guard log holds no raw ssn"; fi
if grep -q 'refused-topic' "$root/c3l6-guardrails/guard.log.jsonl"; then ok "guard log records the topic refusal"; else no "guard log records the topic refusal"; fi

# router: high goes local, low goes hosted stub
out=$(DEMO_STUB="$work/paris.txt" "$root/c4l3-sensitivity-router/run.sh")
expect_eq "router sends 2 prompts local" "$(echo "$out" | grep -c 'route: LOCAL')" "2"
expect_eq "router sends 2 prompts hosted" "$(echo "$out" | grep -c 'route: HOSTED')" "2"

# injection lesson: the scan flags the attack line
out=$(DEMO_STUB="$work/paris.txt" "$root/c3l3-prompt-injection/run.sh")
if echo "$out" | grep -q 'BLOCKED: instruction-like text'; then ok "injection scan flags the attack"; else no "injection scan flags the attack"; fi

printf 'Great product, fast shipping.\n' >"$work/clean-review.txt"
out=$(REVIEW_FILE="$work/clean-review.txt" DEMO_STUB="$work/paris.txt" "$root/c3l3-prompt-injection/run.sh")
if echo "$out" | grep -q 'scan clean'; then ok "injection scan passes a clean review"; else no "injection scan passes a clean review"; fi

# hallucination: an invented name is flagged
printf 'Brightloop was founded by Mark Zuckerman in 2014.' >"$work/halluc.txt"
out=$(DEMO_STUB="$work/halluc.txt" "$root/c3l1-hallucination/run.sh")
if echo "$out" | grep -q 'UNSUPPORTED -> .*Zuckerman'; then ok "source check flags an invented name"; else no "source check flags an invented name"; fi

# checklist
expect_rc "checklist passes on this repo" 0 "$root/c4l4-checklist/run.sh"
mkdir -p "$work/empty-root"
expect_rc "checklist fails on a repo with none of the controls" 1 env CHECK_ROOT="$work/empty-root" "$root/c4l4-checklist/run.sh"

# ---- lessons through stand-ins for apr and curl (tests/bin first on PATH) ----
sp="$root/tests/bin:$PATH"
expect_has() { # name text needle
  case "$2" in *"$3"*) ok "$1" ;; *) no "$1 (missing '$3')" ;; esac
}

out=$(env PATH="$sp" "$root/c1l2-install-pull/run.sh")
expect_has "1.2 shows the install check" "$out" "apr 0.0.0-test"
out=$(env PATH="$sp" "$root/c1l3-run/run.sh")
expect_has "1.3 runs the model once" "$out" "Paris"
out=$(env PATH="$sp" "$root/c1l4-serve-curl/run.sh")
expect_has "1.4 calls the chat endpoint" "$out" "stub reply"
expect_rc "need_server fails when nothing answers" 1 env PATH="$sp" CURL_DOWN=1 "$root/c1l4-serve-curl/run.sh"
out=$(env PATH="$sp" DEMO_MODEL="$root/LICENSE" "$root/c1l5-model-size/run.sh")
expect_has "1.5 prints the model size" "$out" "GiB"
out=$(env PATH="$sp" "$root/c2l1-prompt-basics/run.sh")
expect_has "2.1 prints three answers" "$out" "=== 3. with a constraint"
out=$(env PATH="$sp" "$root/c2l2-cli-chatbot/run.sh" <"$root/c2l2-cli-chatbot/input.txt")
expect_has "2.2 chatbot answers through the server" "$out" "bot> stub reply"
out=$(env PATH="$sp" DEMO_STUB="$work/paris.txt" "$root/c2l2-cli-chatbot/run.sh" <"$root/c2l2-cli-chatbot/input.txt")
expect_has "2.2 chatbot answers through the stub file" "$out" "bot> Paris"
out=$(env PATH="$sp" "$root/c2l3-summarize/run.sh")
expect_has "2.3 summarizes the memo" "$out" "stub reply"
out=$(env PATH="$sp" "$root/c2l4-rag/run.sh")
expect_has "2.4 picks the leave policy for a leave question" "$out" "using leave-policy.txt"
out=$(env PATH="$sp" "$root/c2l4-rag/run.sh" "zzzz qqqq")
expect_has "2.4 refuses to guess when nothing matches" "$out" "refusing to guess"
out=$(env PATH="$sp" "$root/c2l6-tokens-per-sec/run.sh")
expect_has "2.6 prints a rate per run" "$out" "run 3:"
out=$(env PATH="$sp" "$root/c3l2-bias-probes/run.sh")
expect_has "3.2 prints the table" "$out" "praise"
expect_rc "3.4 leak check goes red when redaction is off" 1 env PATH="$sp" REDACT_CMD=cat DEMO_NO_MODEL=1 "$root/c3l4-secrets/run.sh"
out=$(env PATH="$sp" "$root/c3l4-secrets/run.sh")
expect_has "3.4 sends only redacted text to the model" "$out" "only the redacted text goes to the model"
out=$(env PATH="$sp" "$root/c3l5-model-cards/run.sh")
expect_has "3.5 flags missing provenance" "$out" "CHECK license: MISSING"
out=$(env PATH="$sp" APR_INSPECT_MODE=present "$root/c3l5-model-cards/run.sh" "$root/LICENSE")
expect_has "3.5 accepts present provenance" "$out" "CHECK license: present"
out=$(env PATH="$sp" APR_INSPECT_MODE=none "$root/c3l5-model-cards/run.sh")
expect_has "3.5 reports a missing line" "$out" "no line in the inspect output"
out=$(printf 'y\nn\ny\n' | env PATH="$sp" "$root/c4l2-audit-trail/run.sh")
expect_has "4.2 records an approval" "$out" "human: approved"
expect_has "4.2 records a rejection" "$out" "human: rejected"
expect_has "4.2 detects tampering" "$out" "tampering detected"
out=$(env PATH="$sp" "$root/c4l2-audit-trail/run.sh" </dev/null)
expect_has "4.2 a missing decision counts as rejected" "$out" "human: rejected"

# drift lesson (4.5): same answers -> no drift; one different answer -> a diff; an empty answer -> failure
printf 'Paris\n144\nAu\nYes\n366\nShakespeare\n' >"$work/drift-a.txt"
printf 'Paris\n144\nAu\nNo\n366\nShakespeare\n' >"$work/drift-b.txt"
printf 'Paris\n\nAu\nYes\n366\nShakespeare\n' >"$work/drift-empty.txt"
out=$(DRIFT_OUT="$work/d1" DRIFT_STUB_A="$work/drift-a.txt" DRIFT_STUB_B="$work/drift-a.txt" "$root/c4l5-model-drift/run.sh")
expect_has "drift: identical models agree on all probes" "$out" "agreement: 6/6 probes unchanged; drifted: 0"
out=$(DRIFT_OUT="$work/d2" DRIFT_STUB_A="$work/drift-a.txt" DRIFT_STUB_B="$work/drift-b.txt" "$root/c4l5-model-drift/run.sh")
expect_has "drift: one changed answer is flagged" "$out" "DRIFT  q=Is the Pacific Ocean"
expect_has "drift: the summary counts one drift" "$out" "drifted: 1"
expect_rc "drift: an empty answer fails the run" 1 env DRIFT_OUT="$work/d3" DRIFT_STUB_A="$work/drift-a.txt" DRIFT_STUB_B="$work/drift-empty.txt" "$root/c4l5-model-drift/run.sh"
out=$(env PATH="$sp" DRIFT_OUT="$work/d4" "$root/c4l5-model-drift/run.sh")
expect_has "drift: runs through apr when no stub is set" "$out" "agreement: 6/6"
expect_rc "drift: a model that prints nothing fails the run" 1 env PATH="$sp" APR_RUN_ANSWER= DRIFT_OUT="$work/d5" "$root/c4l5-model-drift/run.sh"

# server scripts
expect_rc "serve.sh brings the stub server up" 0 env PATH="$sp" "$root/scripts/serve.sh"
out=$("$root/scripts/stop.sh")
expect_eq "stop.sh stops the recorded pid" "$out" "stopped"
: >"$root/.run/serve.pid"
out=$("$root/scripts/stop.sh")
expect_eq "stop.sh reports a missing pid file" "$out" "no pid file"
expect_rc "serve.sh fails when the server never answers" 1 env PATH="$sp" CURL_DOWN=1 SERVE_WAIT=1 "$root/scripts/serve.sh"

# capture.sh: sanitized output, the home directory never lands in the file
mkdir -p "$work/cap"
env PATH="$sp" CAPTURE_DIR="$work/cap" "$root/scripts/capture.sh" c1l3-run >/dev/null
if grep -q "$HOME" "$work/cap/c1l3-run.out"; then no "capture.sh strips the home directory"; else ok "capture.sh strips the home directory"; fi
expect_eq "capture.sh records the exit code" "$(tail -n 1 "$work/cap/c1l3-run.out")" "# exit code: 0"
env PATH="$sp" CAPTURE_DIR="$work/cap" "$root/scripts/capture.sh" c1l4-serve-curl "$root/LICENSE" >/dev/null
expect_eq "capture.sh takes an input file" "$(tail -n 1 "$work/cap/c1l4-serve-curl.out")" "# exit code: 0"
env PATH="$sp" CURL_DOWN=1 CAPTURE_DIR="$work/cap" "$root/scripts/capture.sh" c1l4-serve-curl >/dev/null
expect_eq "capture.sh records a failing lesson" "$(tail -n 1 "$work/cap/c1l4-serve-curl.out")" "# exit code: 1"

# gates
out=$(env PATH="$sp" "$root/scripts/gate-lint.sh")
expect_has "lint gate passes and counts files" "$out" "lint OK"
expect_rc "lint gate fails on a lint error" 1 env PATH="$sp" BASHRS_RC=1 "$root/scripts/gate-lint.sh"
expect_rc "lint gate fails on 0 files" 1 env PATH="$sp" LINT_FILES= "$root/scripts/gate-lint.sh"
expect_rc "nopython gate passes on this repo" 0 "$root/scripts/gate-nopython.sh"
expect_rc "nopython gate fails on 0 files" 1 env NOPY_FILES= "$root/scripts/gate-nopython.sh"
printf 'x = 1\n' >"$work/bad.py"
expect_rc "nopython gate fails on a .py file" 1 env NOPY_FILES="$work/bad.py" "$root/scripts/gate-nopython.sh"
printf "%s -c x\n" py"thon3" >"$work/call.sh"
expect_rc "nopython gate fails on an interpreter call" 1 env NOPY_FILES="$work/call.sh" "$root/scripts/gate-nopython.sh"


# ---- three-runtime lessons 1.1.0 to 1.1.5 through stand-ins for apr, llama-cli, ollama and curl ----
out=$(env PATH="$sp" "$root/c1l0-local-or-hosted/run.sh")
expect_has "1.1.0 shows the llama.cpp version" "$out" "version: 0.0.0-test"
expect_has "1.1.0 shows the Ollama version" "$out" "ollama version is 0.0.0-test"
expect_has "1.1.0 answers one prompt offline" "$out" "Paris"
out=$(env PATH="$sp" RISK_DIR="$work/risk" "$root/c1l1-risk-register/run.sh")
expect_has "1.1.1 writes four risks" "$out" "leaked-data you -"
expect_has "1.1.1 counts four lines" "$out" "4 risks.md"
out=$(env PATH="$sp" "$root/c1l2-install-pull/runtimes.sh")
expect_has "1.1.2 shows the Ollama model" "$out" "architecture stub"
expect_has "1.1.2 shows the llama.cpp cache" "$out" "number of models in cache: 0"
out=$(env PATH="$sp" "$root/c1l3-run/runtimes.sh")
expect_has "1.1.3 runs apr" "$out" "Paris"
expect_has "1.1.3 runs llama.cpp" "$out" "stub llama reply"
expect_has "1.1.3 runs Ollama" "$out" "stub ollama reply"
out=$(env PATH="$sp" RUN_DIR="$work/run" "$root/c1l4-serve-curl/runtimes.sh")
expect_has "1.1.4 calls apr" "$out" "stub reply"
expect_has "1.1.4 calls Ollama native chat" "$out" "stub ollama chat"
expect_has "1.1.4 sends the broken body" "$out" "the same call with a broken bracket"
out=$(env PATH="$sp" RUN_DIR="$work/run" CURL_DOWN=1 SERVE_WAIT=1 "$root/c1l4-serve-curl/runtimes.sh")
expect_has "1.1.4 reports a server that never answers" "$out" "apr serve did not answer /health"
out=$(env PATH="$sp" "$root/c1l5-model-size/runtimes.sh")
expect_has "1.1.5 reads the licence" "$out" "Apache License"
expect_has "1.1.5 runs llama.cpp" "$out" "stub llama reply"

# show: the exit code of the shown command is not propagated, and control codes are stripped
out=$(show printf 'a\033[31mb\n')
expect_eq "show prints the command and strips control codes" "$out" "$(printf '%s\n%s' '$ printf a\033[31mb\n' 'ab')"
expect_rc "show survives a failing command" 0 show false

# demo-home: scratch home with symlinks to the runtimes and a copy of the GGUF file
home="$work/demo-home"
mkdir -p "$work/fake-home/.cache/pacha/models"
printf 'x' >"$work/fake-home/.cache/pacha/models/qwen-1.5b-q4k.apr"
out=$(env PATH="$sp" HOME="$work/fake-home" DEMO_GGUF="$root/LICENSE" "$root/scripts/demo-home.sh" "$home")
expect_has "demo-home reports the directory" "$out" "demo home ready"
if [ -L "$home/bin/ollama" ] && [ -f "$home/.cache/pacha/models/LICENSE" ] && [ -L "$home/.cache/pacha/models/qwen-1.5b-q4k.apr" ]; then ok "demo-home links the tools and the models"; else no "demo-home links the tools and the models"; fi
expect_rc "demo-home refuses a dir with .." 1 env PATH="$sp" HOME="$work/fake-home" DEMO_GGUF="$root/LICENSE" "$root/scripts/demo-home.sh" "$work/a/../b"

# leak gate: the fixtures are built from pieces so this file does not trip the scan itself
printf 'plain text\n' >"$work/leak-clean.txt"
printf '%s%s\n' "AKIA" "ABCDEFGHIJKLMNOP" >"$work/leak-key.txt"
printf '%s%s\n' "cd /mn" "t/data" >"$work/leak-path.txt"
expect_rc "leak gate passes a clean file" 0 env LEAK_FILES="$work/leak-clean.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on a key shape" 1 env LEAK_FILES="$work/leak-key.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on a local path" 1 env LEAK_FILES="$work/leak-path.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate fails on 0 files" 1 env LEAK_FILES= "$root/scripts/gate-leaks.sh"
printf 'theme = "%s-dark"\n' "rme""dia" >"$work/leak-theme.txt"
expect_rc "leak gate allows the scene theme name" 0 env LEAK_FILES="$work/leak-theme.txt" "$root/scripts/gate-leaks.sh"
printf 'theme = "%s-dark"\n%s%s\n' "rme""dia" "cd /mn" "t/data" >"$work/leak-theme2.txt"
expect_rc "leak gate still fails a path beside the theme" 1 env LEAK_FILES="$work/leak-theme2.txt" "$root/scripts/gate-leaks.sh"
expect_rc "leak gate passes this repo" 0 "$root/scripts/gate-leaks.sh"

echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
