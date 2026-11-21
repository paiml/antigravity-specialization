#!/bin/bash
# Trims whitespace and converts ASCII lowercase to uppercase.

set -euo pipefail

tr '[:lower:]' '[:upper:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
