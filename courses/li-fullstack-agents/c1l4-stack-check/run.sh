#!/usr/bin/env bash
# Lesson 1.1.4: Choose a minimal stack. RUNS: version checks, the sqlite feature check, and the decision log format.
# node:sqlite prints an ExperimentalWarning; that is expected and the script says so.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms v1.0.0 "$WORK/app"
say "versions"
echo "node: $(node --version)"
echo ".nvmrc: $(cat "$WORK/app/.nvmrc")"
say "node:sqlite is built in (expect an ExperimentalWarning on stderr)"
node -e "const {DatabaseSync}=require('node:sqlite');const d=new DatabaseSync(':memory:');d.exec('create table t(x)');d.exec('insert into t values (42)');console.log('sqlite answer:', d.prepare('select x from t').get().x);" 2>&1 | sed 's/^/  /'
say "no dependencies"
if grep -q '"dependencies"' "$WORK/app/package.json"; then echo "FAIL package.json lists dependencies"; exit 1; fi
echo "ok    package.json has no dependencies block"
say "decision log: every entry names options, a choice, a reason and a cost"
bad=0
n=$(grep -c '^## D[0-9]' "$WORK/app/DECISIONS.md")
echo "decisions: $n"
for w in Options Chosen Why Cost; do
  c=$(grep -c "$w" "$WORK/app/DECISIONS.md")
  if [ "$c" -ge "$n" ]; then echo "ok    '$w' appears in every entry ($c)"; else echo "FAIL '$w' missing from some entry ($c of $n)"; bad=1; fi
done
agy_step "$here/prompts/stack-review.md" plan "$WORK/app"
exit "$bad"
