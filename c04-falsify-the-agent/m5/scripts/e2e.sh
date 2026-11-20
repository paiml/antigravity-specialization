#!/usr/bin/env bash
# Probar end to end for the m5 wasm page.
# Builds m5 for wasm32, runs wasm-bindgen, then drives every control in
# headless Chrome and reads the state back. Checks for its tools; installs nothing.
#   M5_CHROME=/path/to/chrome-headless-shell m5/scripts/e2e.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${M5_CHROME:?set M5_CHROME to a headless Chrome binary}"
command -v wasm-bindgen >/dev/null || { echo "e2e: missing tool: wasm-bindgen" >&2; exit 1; }
rustup target list --installed | grep -qx wasm32-unknown-unknown \
  || { echo "e2e: wasm32-unknown-unknown target not installed" >&2; exit 1; }
want="$(grep -m1 '^wasm-bindgen = ' Cargo.toml | tr -dc '0-9.')"
have="$(wasm-bindgen --version | awk '{print $2}')"
[ "$want" = "$have" ] || { echo "e2e: wasm-bindgen $have, Cargo.toml pins $want" >&2; exit 1; }
target="${CARGO_TARGET_DIR:-$PWD/target}"
cargo build --locked --lib --release --target wasm32-unknown-unknown
out="$target/m5-web"
mkdir -p "$out"
wasm-bindgen --target web --no-typescript --out-dir "$out" \
  "$target/wasm32-unknown-unknown/release/m5.wasm"
M5_WEB_DIR="$out" cargo test --locked --features e2e --test e2e_probar -- --nocapture
