//! Shrinking, reading the counterexample.
//!
//! Provable contract: the `IN_RANGE` failure shrinks to `x = 0, hi = 0, lo > hi`,
//! and proptest saves it to the regression file named by the
//! first argument, so the next run replays it first.

use m3::props::{any_case, find_escape, is_shrunk_escape};
use std::path::PathBuf;

fn main() {
    let path = std::env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::temp_dir().join("m3-shrink-regressions.txt"));
    let case = find_escape(any_case(), Some(&path)).expect("lo > hi escapes");
    println!("shrunk counterexample (x, lo, hi) = {case:?}");
    println!("clamp{case:?} = {}", m3::clamp(case.0, case.1, case.2));
    assert!(is_shrunk_escape(case));

    let saved = std::fs::read_to_string(&path).expect("proptest wrote the regression file");
    let line = saved
        .lines()
        .find(|l| l.starts_with("cc "))
        .expect("one cc line");
    println!("regression file {}: {line}", path.display());
    assert!(line.contains("shrinks to"));

    let replayed = find_escape(any_case(), Some(&path));
    assert_eq!(replayed, Some(case));
    println!("contract: m3-shrink reversed-bounds counterexample saved and replayed OK");
}
