//! From examples to properties.
//!
//! Provable contract: the example test of `clamp` is green, `IN_RANGE` holds on 256
//! generated cases with `lo <= hi`, and the same property finds a counterexample
//! with `lo > hi` when the precondition is dropped.

use m3::props::{any_case, find_escape, ordered_case, CASES};

fn main() {
    let example = m3::clamp(9, 0, 5);
    println!("example: clamp(9, 0, 5) = {example}");
    assert_eq!(example, 5);

    let ordered = find_escape(ordered_case(), None);
    println!(
        "property IN_RANGE, lo <= hi, {CASES} cases: {}",
        verdict(ordered)
    );
    assert_eq!(ordered, None);

    let any = find_escape(any_case(), None);
    println!(
        "property IN_RANGE, any bounds, {CASES} cases: {}",
        verdict(any)
    );
    let (x, lo, hi) = any.expect("dropping lo <= hi lets clamp escape");
    assert!(lo > hi);

    println!("contract: m3-props example green, ordered property holds, clamp({x}, {lo}, {hi}) escapes OK");
}

fn verdict(found: Option<(i64, i64, i64)>) -> String {
    match found {
        None => "held".to_string(),
        Some(case) => format!("FAILED at (x, lo, hi) = {case:?}"),
    }
}
