#!/bin/bash
set -euo pipefail

SOURCE_FILE="fixtures/target.txt"
[ -s "$SOURCE_FILE" ] || { echo "error: missing input: $SOURCE_FILE" >&2; exit 1; }
wc -l < "$SOURCE_FILE"
