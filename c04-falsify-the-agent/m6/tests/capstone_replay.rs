//! The capstone code in `src/shop.rs` IS the recorded agent patch.
//! CI replays the record; it never calls agy.

const PATCH: &str = include_str!("../fixtures/agy-runs/m6-capstone/patch.diff");
const SHOP: &str = include_str!("../src/shop.rs");
const MARKER: &str = "// ---- recorded agent output below ----\n";

/// The lines the agent added, without the leading `+`.
fn added_lines() -> Vec<&'static str> {
    PATCH
        .lines()
        .filter(|l| l.starts_with('+') && !l.starts_with("+++"))
        .map(|l| &l[1..])
        .collect()
}

#[test]
fn shop_rs_is_the_agent_patch_minus_one_blank_line() {
    let added = added_lines();
    // The agent's patch opens with a blank line under the existing doc line and
    // ends with a blank line: the one `cargo fmt -- --check` refuses (gate fmt: FAIL).
    assert_eq!(added.first(), Some(&""));
    assert_eq!(added.last(), Some(&""));
    let body = &added[1..added.len() - 1];
    let (_, recorded) = SHOP.split_once(MARKER).expect("marker line present");
    let ours: Vec<&str> = recorded.lines().collect();
    assert_eq!(ours, body);
}
