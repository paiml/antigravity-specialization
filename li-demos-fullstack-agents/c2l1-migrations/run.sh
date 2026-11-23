#!/usr/bin/env bash
# Lesson 2.1.1: Data model and migrations. RUNS: apply the migrations to a scratch file, read the schema back with sqlite3,
# prove the constraints reject bad rows, prove a second run applies nothing. BLOCKED when agy has no quota: the migration prompt.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
need_node || exit 1
new_workdir
copy_ms ch2-done "$WORK/app"
agy_step "$here/prompts/migrations.md" accept-edits "$WORK/app"
cd "$WORK/app" || exit 1
say "the migration files"
for f in migrations/*.sql; do echo "== $f"; cat "$f"; done
say "apply them (expect an ExperimentalWarning from node:sqlite)"
node -e "require('./db').openDb(process.argv[1]).close()" "$WORK/t.db" 2>&1 | sed 's/^/  /'
say "schema read back with the sqlite3 shell"
sql "$WORK/t.db" .schema
say "migrations recorded"
sql "$WORK/t.db" 'select name from schema_migrations order by name'
say "constraints: an empty title and an unknown status must both be refused"
if sql "$WORK/t.db" "insert into tasks(title) values ('')" 2>&1; then echo "FAIL empty title accepted"; exit 1; fi
if sql "$WORK/t.db" "insert into tasks(title,status) values ('x','blocked')" 2>&1; then echo "FAIL bad status accepted"; exit 1; fi
say "a second run applies nothing new"
node -e "require('./db').openDb(process.argv[1]).close()" "$WORK/t.db" 2>/dev/null
n=$(sql "$WORK/t.db" 'select count(*) from schema_migrations')
echo "rows in schema_migrations: $n"
if [ "$n" -ne 2 ]; then echo "FAIL expected 2"; exit 1; fi
