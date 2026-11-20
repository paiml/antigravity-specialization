//! m4: falsifiers: can the gate refuse an empty artifact.
//!
//! One module per demo:
//! - [`report`]: reads a `cargo test` / libtest report into counts.
//! - [`gate`]: a pass-rate gate with no floor (`m4_empty_gate`) and with one (`m4_falsifier`).
//! - [`falsifier`]: the one input that must make a gate red (`m4_falsifier`).
//! - [`lint`]: reads `pv lint` summaries and names the levers that hide a finding (`m4_waiver_levers`).
//! - [`referee`]: refuses a patch that edits the gate itself (`m4_referee`).

pub mod falsifier;
pub mod gate;
pub mod lint;
pub mod referee;
pub mod report;
