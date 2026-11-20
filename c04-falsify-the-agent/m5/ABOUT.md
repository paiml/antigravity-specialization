# m5: End to end for agent-built web and WASM

Each demo is a bin under `src/bin/` with a `Provable contract:` docstring line,
a closing `assert!` and `println!("contract: ... OK")`. The pv contracts live in
`m5/contracts/` (with `binding.yaml`); `scripts/gate.sh` checks every `m*/contracts` it finds.

## The page

A recorder page with Record, Stop and Save. The logic is plain Rust: `src/ui.rs` (state
machine), `src/page.rs` (controls and HTML). The browser layer is `src/web.rs`, built through
wasm-bindgen for `wasm32` only; wasm-bindgen generates the JavaScript glue, none is written by
hand.

| Bin | Red-first case |
|---|---|
| `m5_curl_is_not_a_test` | A dead Save button: the GET says 200 with every id; the driver refuses step 2 (save). |
| `m5_control_contract` + `contracts/record-ui-v1.yaml` | `fixtures/red/record-ui-no-falsify.yaml`: `pv validate` exit 0, `pv score --min-score 0.6 --exit-code` exit 1. |
| `m5_drive_every_control` | A script without the save step leaves `["save"]` unexercised. |
| `m5_read_the_result_back` | A Save that only writes "Saved" passes the label check and fails the read-back. |

The step driver (`src/driver.rs`) is this crate's own Rust model of an end-to-end run.

## The browser run

`tests/e2e_probar.rs` (feature `e2e`, jugar-probar) loads the real wasm-bindgen page in headless
Chrome, clicks `#save`, `#record`, `#stop`, `#save`, `#save`, `#record`, `#stop`, and reads the
`#status` text and `data-state` back against the Rust model. Run it with

    M5_CHROME=/path/to/chrome-headless-shell m5/scripts/e2e.sh

It needs the `wasm32-unknown-unknown` target, `wasm-bindgen` at the version `Cargo.toml` pins, and
a headless Chrome. It checks for each and installs nothing. It is not part of `scripts/gate.sh`
or CI: the CI container has no Chrome, and a CI job installs nothing.
