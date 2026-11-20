//! m5: End to end for agent-built web and WASM.
//!
//! A recorder page with Record, Stop and Save buttons. The page logic is plain Rust
//! ([`ui`], [`page`]); the browser layer is wasm-bindgen ([`web`], wasm32 only).
//! The checks are a curl-style GET ([`curl`]), a step driver that reads the
//! state back ([`driver`]) and an export list read from `web.rs` ([`exports`]).

pub mod contract;
pub mod curl;
pub mod driver;
pub mod exports;
pub mod page;
pub mod ui;

#[cfg(target_arch = "wasm32")]
pub mod web;
