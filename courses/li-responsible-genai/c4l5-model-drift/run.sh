#!/usr/bin/env bash
# Lesson 4.5: model drift. Run the same fixed probe set against two model files and diff the answers.
# MODEL_A is the model you trust today; MODEL_B is the candidate (a new version, a smaller size, another quantization).
# Test hook: DRIFT_STUB_A / DRIFT_STUB_B (files, one answer per line) replace the model runs.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
MODEL_A="${MODEL_A:-$DEMO_MODEL}"
MODEL_B="${MODEL_B:-$HOME/.cache/pacha/models/8de7eb9c0c789ccb.gguf}"
out="${DRIFT_OUT:-$here/out}"
mkdir -p "$out"

# answer_with MODEL STUBFILE PROMPT N: one answer on one line.
answer_with() {
  local model="$1" stub="$2" prompt="$3" n="$4"
  if [ -n "$stub" ]; then
    sed -n "${n}p" "$stub"
    return 0
  fi
  apr run "$model" "$prompt" --chat -n 24 --no-gpu --offline 2>/dev/null |
    awk '/^Output:/{on=1; next} /^Completed in/{on=0} on && NF' | tr '\n' ' ' | sed -E 's/ +$//'
  echo
}

# run_set MODEL STUBFILE OUTFILE: one answer per probe.
run_set() {
  local n=0 q
  : >"$3"
  while IFS= read -r q; do
    [ -z "$q" ] && continue
    n=$((n + 1))
    answer_with "$1" "$2" "$q" "$n" >>"$3"
  done <"${DRIFT_PROBES:-$here/data/probes.txt}"
}

echo "model A: $(basename "$MODEL_A")"
echo "model B: $(basename "$MODEL_B")"
run_set "$MODEL_A" "${DRIFT_STUB_A:-}" "$out/answers-a.txt"
run_set "$MODEL_B" "${DRIFT_STUB_B:-}" "$out/answers-b.txt"

total=$(grep -c . "${DRIFT_PROBES:-$here/data/probes.txt}")
same=0 empty=0 n=0
while IFS= read -r q; do
  [ -z "$q" ] && continue
  n=$((n + 1))
  a=$(sed -n "${n}p" "$out/answers-a.txt")
  b=$(sed -n "${n}p" "$out/answers-b.txt")
  if [ -z "$a" ] || [ -z "$b" ]; then empty=$((empty + 1)); fi
  if [ "$a" = "$b" ]; then
    mark=SAME
    same=$((same + 1))
  else
    mark=DRIFT
  fi
  printf '%s  q=%s\n        A=%s\n        B=%s\n' "$mark" "$q" "$a" "$b"
done <"${DRIFT_PROBES:-$here/data/probes.txt}"

echo "--- diff of answers (A vs B) ---"
diff -u --label "A: $(basename "$MODEL_A")" --label "B: $(basename "$MODEL_B")" "$out/answers-a.txt" "$out/answers-b.txt" || true
echo "agreement: $same/$total probes unchanged; drifted: $((total - same))"
if [ "$empty" -gt 0 ]; then
  echo "FAIL: $empty probe(s) got no answer from a model"
  exit 1
fi
echo "re-check done: review each DRIFT line before you switch models"
