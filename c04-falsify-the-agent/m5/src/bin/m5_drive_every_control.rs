//! m5_drive_every_control: drive every control.
//!
//! Provable contract: every `#[wasm_bindgen]` export in `src/web.rs` is
//! clicked by a driver step; a script that skips one export is refused, by
//! name.

use m5::driver::recorder_script;
use m5::exports::{exported_fns, unexercised, WEB_RS};

fn main() {
    let exports = exported_fns(WEB_RS);
    println!("wasm-bindgen exports in web.rs: {exports:?}");

    let full = recorder_script();
    let partial: Vec<_> = full
        .iter()
        .copied()
        .filter(|s| s.control != "save")
        .collect();
    let missed = unexercised(&exports, &partial);
    println!("script without the save step leaves unexercised: {missed:?}");
    let none = unexercised(&exports, &full);
    println!("full script leaves unexercised: {none:?}");

    assert_eq!(exports, ["record", "stop", "save"]);
    assert_eq!(missed, ["save"]);
    assert!(none.is_empty());
    println!("contract: every wasm-bindgen export is driven, a skipped one is named OK");
}
