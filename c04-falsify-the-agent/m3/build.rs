//! Declares `cfg(kani)` so the Kani harness in `src/proofs.rs` compiles clean
//! under `cargo clippy -D warnings`, where Kani is not running.

fn main() {
    println!("cargo::rustc-check-cfg=cfg(kani)");
}
