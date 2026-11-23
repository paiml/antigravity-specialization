#!/usr/bin/env bash
# demo-home.sh [DIR]: build the scratch home the terminal scenes capture in (off camera setup).
# DIR holds symlinks to the runtimes (bin/) and one small GGUF file, copied once so that
# `apr list` shows its real size. Nothing is downloaded and nothing outside DIR is touched.
# Env: DEMO_GGUF names the GGUF file (default: the file lib/common.sh names).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/lib/common.sh"
dir="${1:-/tmp/rg-home}"
case "$dir" in
  *..*) echo "demo-home: dir must not contain .." >&2; exit 1 ;;
esac
mkdir -p "$dir/bin" "$dir/models" "$dir/.cache/pacha/models"
for tool in apr llama-cli llama-server ollama curl jq; do
  ln -sf "$(command -v "$tool")" "$dir/bin/$tool"
done
cp -n "$DEMO_GGUF" "$dir/.cache/pacha/models/$(basename "$DEMO_GGUF")"
ln -sf "$dir/.cache/pacha/models/$(basename "$DEMO_GGUF")" "$dir/models/qwen2.5-0.5b-instruct-q5_0.gguf"

# lessons 2.1 to 4.4 serve the 1.5B apr model; link it when it is installed (read-only, not copied)
model15="$HOME/.cache/pacha/models/qwen-1.5b-q4k.apr"
if [ -f "$model15" ]; then
  ln -sf "$model15" "$dir/.cache/pacha/models/qwen-1.5b-q4k.apr"
fi
echo "demo home ready: $dir"
