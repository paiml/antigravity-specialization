//! Mutation testing: who tests the tests.
//!
//! The demo code under test (`price`, `cap`, `bulk`, `agent_shipping`) and the
//! readers that judge saved `cargo mutants` runs (`score`, `diff`, `demos`).
//! Every number a demo shows comes from a saved run under `m2/mutants/`.

pub mod agent_shipping;
pub mod bulk;
pub mod cap;
pub mod demos;
pub mod diff;
pub mod price;
pub mod score;

use std::path::PathBuf;

/// Saved `cargo mutants` runs, one directory per demo.
pub fn mutants_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("mutants")
}

/// The recorded agy run that `m2_agent_suite` replays.
pub fn agy_run_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../fixtures/agy-runs/m2-agent-suite")
}
