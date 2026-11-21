#!/bin/bash
# Processes input records without strict mode.
INPUT="${1:-}"
grep -v '^#' "$INPUT" > "$2"
