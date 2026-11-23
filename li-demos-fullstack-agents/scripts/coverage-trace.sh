#!/usr/bin/env bash
# Line coverage of the repo's shell code by the offline tests, measured with bash's own xtrace.
# No coverage tool for bash exists in the installed toolchain (`bashrs coverage` only counts test_* functions),
# so this script runs tests/run-tests.sh with xtrace on and compares the lines that ran with the lines that can run.
# Executable lines = every line except blank, comment, syntax-only (do/done/fi/else/then/esac/;;/}), function
# header, continuation and multi-line string interior lines. Files under tests/ are fixtures, not measured,
# and this script (the measuring tool, which cannot trace itself) is excluded too.
# Usage: scripts/coverage-trace.sh [MIN_PERCENT]   (exit 1 when below MIN_PERCENT; default 100)
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root" || exit 1
min="${1:-100}"
work="${COVERAGE_WORK:-$root/.run/coverage}"
mkdir -p "$work"
trace="$work/trace.txt"
: >"$trace"

exec 9>>"$trace"
env COVERAGE_RUN=1 BASH_XTRACEFD=9 SHELLOPTS=xtrace PS4='+TRACE ${BASH_SOURCE[0]}:${LINENO}: ' \
  "$root/tests/run-tests.sh" >"$work/tests.out" 2>&1
test_rc=$?
exec 9>&-
echo "tests exit code: $test_rc ($(tail -n 1 "$work/tests.out"))"

# hit lines: "relative/file:LINE" taken from the trace, with the repo prefix removed.
sed -nE 's/^\++TRACE ([^:]+):([0-9]+): .*/\1:\2/p' "$trace" | sed -E "s#^$root/##; s#^\./##; s#[^/]+/\.\./##" | sort -u >"$work/hit.txt"

# exec_lines FILE: print the line numbers that count as executable.
exec_lines() {
  awk '
    function quotes(s,   t, n) {
      t = s
      gsub(/\\"/, "", t)
      gsub(/\047[^\047]*\047/, "", t)
      n = gsub(/"/, "", t)
      return n
    }
    {
      line = $0
      stripped = line
      sub(/^[ \t]+/, "", stripped)
      skip = 0
      if (inq) { skip = 1 }
      else if (stripped == "" || stripped ~ /^#/) { skip = 1 }
      else if (stripped ~ /^(do|fi|else|then|esac|;;|\}|\{)$/) { skip = 1 }
      else if (stripped ~ /^done( |$)/) { skip = 1 }
      else if (stripped ~ /^[A-Za-z_][A-Za-z0-9_]*\(\) *\{$/) { skip = 1 }
      else if (cont) { skip = 1 }
      if (!skip) ustart = NR
      if (quotes(line) % 2 == 1) inq = !inq
      t = stripped
      sub(/[ \t]+$/, "", t)
      cont = (t ~ /(\\|\||&&|\|\|)$/ && t !~ /^#/) ? 1 : 0
      if (!inq && !cont && ustart > 0) { print ustart "-" NR; ustart = 0 }
    }
  ' "$1"
}

total=0 hit=0
: >"$work/missed.txt"
files=$(git ls-files '*.sh' '*/run.sh' | grep -v -e '^tests/' -e '^milestones/' -e '^scripts/coverage-trace.sh$' | sort -u)
printf '%-40s %6s %6s %7s\n' file lines hit pct
for f in $files; do
  n=0 h=0
  while IFS=- read -r first last; do
    n=$((n + 1))
    seen=0
    for ((ln = first; ln <= last; ln++)); do
      if grep -qxF "$f:$ln" "$work/hit.txt"; then seen=1; fi
    done
    if [ "$seen" -eq 1 ]; then
      h=$((h + 1))
    else
      echo "$f:$first: $(sed -n "${first}p" "$f")" >>"$work/missed.txt"
    fi
  done < <(exec_lines "$f")
  total=$((total + n))
  hit=$((hit + h))
  pct=100
  if [ "$n" -gt 0 ]; then pct=$((h * 100 / n)); fi
  printf '%-40s %6s %6s %6s%%\n' "$f" "$n" "$h" "$pct"
done
if [ "$total" -eq 0 ]; then echo "FAIL measured 0 lines"; exit 1; fi
echo "TOTAL executable lines $total, hit $hit, missed $((total - hit)) ($((hit * 1000 / total / 10)).$((hit * 1000 / total % 10))%)"
if [ "$((total - hit))" -gt 0 ]; then
  echo "--- missed lines (also in $work/missed.txt)"
  head -n 60 "$work/missed.txt"
fi
if [ "$test_rc" -ne 0 ]; then echo "FAIL the tests failed"; exit 1; fi
if [ "$((hit * 100 / total))" -lt "$min" ]; then echo "FAIL coverage below $min%"; exit 1; fi
echo "coverage OK (>= $min%)"
