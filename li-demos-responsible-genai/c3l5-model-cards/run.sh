#!/usr/bin/env bash
# Lesson 3.5: read the model's own provenance before running it. Fail the check when the license is missing.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/../lib/common.sh"
model="${1:-$DEMO_MODEL}"
info=$(apr inspect "$model")
echo "$info" | sed -n '/Architecture:/,/Chat Template:/p' | grep -v 'Chat Template:'
for field in license data_source data_license; do
  line=$(echo "$info" | grep -E "^ *$field:" | head -n 1 || true)
  case "$line" in
    "") echo "CHECK $field: no line in the inspect output" ;;
    *"(missing)"*) echo "CHECK $field: MISSING -> read the upstream model card before any real use" ;;
    *) echo "CHECK $field: present ->${line#*:}" ;;
  esac
done
