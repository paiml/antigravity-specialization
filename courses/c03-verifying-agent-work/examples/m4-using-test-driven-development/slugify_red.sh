#!/bin/bash
# RED stub: naive implementation that leaves punctuation, double dashes,
# and accepts empty input with exit 0.

RAW="${1:-}"
printf '%s\n' "$RAW" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
