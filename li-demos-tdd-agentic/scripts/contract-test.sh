#!/usr/bin/env bash
# contract-test.sh DIR CONTRACT_YAML: turn the cases in a small YAML contract into test lines and run them.
set -uo pipefail
dir="$1"
contract="$2"
cases="$dir/.contract-cases.txt"
awk '
  /^    max: / { max = $2 }
  /^    in: "/ { s = $0; sub(/^    in: "/, "", s); sub(/"$/, "", s); inp = s }
  /^    out: "/ { s = $0; sub(/^    out: "/, "", s); sub(/"$/, "", s);
            if (max == "") max = "-";
            print max "|" inp "|" s; max = "" }
' "$contract" >"$cases"
echo "contract-test: $(grep -c . "$cases") cases from $(basename "$contract")"
CASES="$cases" bash "$dir/tests/run.sh"
