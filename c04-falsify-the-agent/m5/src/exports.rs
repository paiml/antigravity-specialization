//! The wasm-bindgen exports, read from the source that declares them.
//!
//! Every exported control must be clicked by at least one driver step. An
//! export no step calls is a control nobody tested.

use crate::driver::Step;

/// The source of the wasm-bindgen layer, as compiled into the page.
pub const WEB_RS: &str = include_str!("web.rs");

/// Names of `pub fn` items marked with a bare `#[wasm_bindgen]` line.
///
/// `#[wasm_bindgen(start)]` is the page's entry point, not a control, so it
/// does not match.
pub fn exported_fns(src: &str) -> Vec<String> {
    let mut names = Vec::new();
    let mut marked = false;
    for line in src.lines().map(str::trim) {
        if line == "#[wasm_bindgen]" {
            marked = true;
            continue;
        }
        if marked {
            if let Some(rest) = line.strip_prefix("pub fn ") {
                let name: String = rest
                    .chars()
                    .take_while(|c| c.is_alphanumeric() || *c == '_')
                    .collect();
                names.push(name);
            }
        }
        marked = false;
    }
    names
}

/// Exports that no step clicks, in source order.
pub fn unexercised(exports: &[String], steps: &[Step]) -> Vec<String> {
    exports
        .iter()
        .filter(|name| !steps.iter().any(|s| s.control == name.as_str()))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::driver::{recorder_script, Expect};

    #[test]
    fn finds_marked_fns_and_skips_start_and_unmarked() {
        let src = "#[wasm_bindgen(start)]\npub fn start() {}\n#[wasm_bindgen]\npub fn record() {}\npub fn helper() {}\n#[wasm_bindgen]\nfn private() {}\n";
        assert_eq!(exported_fns(src), vec!["record".to_string()]);
    }

    #[test]
    fn every_export_in_web_rs_is_driven() {
        let exports = exported_fns(WEB_RS);
        assert!(!exports.is_empty(), "web.rs exports nothing");
        assert_eq!(
            unexercised(&exports, &recorder_script()),
            Vec::<String>::new()
        );
    }

    #[test]
    fn an_export_with_no_step_is_reported() {
        let exports = vec!["record".to_string(), "stop".to_string()];
        let steps = [Step {
            control: "record",
            expect: Expect::Takes(0),
        }];
        assert_eq!(unexercised(&exports, &steps), vec!["stop".to_string()]);
    }
}
