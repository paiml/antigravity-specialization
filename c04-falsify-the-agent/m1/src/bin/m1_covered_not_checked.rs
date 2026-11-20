//! Lesson 1.3: 100% is a claim, not a fact.
//!
//! Two suites for the same crate, both at 100% line coverage (measured on
//! build-host with `cargo llvm-cov`): the agent's recorded suite and a hand-written
//! suite that runs every line and checks nothing. Coverage cannot tell them
//! apart. Counting assertions per test can.
//!
//! The count is textual (`assert!`, `assert_eq!`, `assert_ne!`, `panic!`,
//! `#[should_panic]`); a test that checks through `.unwrap()` or a helper is
//! not counted and would be refused.
//!
//! Provable contract: both suites cover 100% of lines; the assertion count
//! accepts the agent suite and refuses the hand-written vacuous suite.

use m1::asserts::{added_lines, suite_accepted, test_asserts, unchecked};
use m1::measured::llvm_cov_lines;

const AGENT_PATCH: &str = include_str!("../../../fixtures/agy-runs/m1-cold-open/patch.diff");
const AGENT_COV: &str =
    include_str!("../../../fixtures/agy-runs/m1-cold-open/measured/llvm-cov-after.txt");
const VACUOUS_SRC: &str = include_str!("../../fixtures/vacuous-suite/src/lib.rs");
const VACUOUS_COV: &str = include_str!("../../fixtures/vacuous-suite/measured/llvm-cov-after.txt");

fn main() {
    let agent = test_asserts(&added_lines(AGENT_PATCH));
    let vacuous = test_asserts(VACUOUS_SRC);
    let suites = [
        ("agent suite (recorded)", &agent, AGENT_COV),
        ("vacuous suite (hand-written)", &vacuous, VACUOUS_COV),
    ];
    for (name, tests, cov) in suites {
        let (lines, missed) = llvm_cov_lines(cov).expect("TOTAL row");
        println!("{name}: lines {}/{lines} covered", lines - missed);
        for t in tests.iter() {
            println!("  {:<58} asserts {}", t.name, t.asserts);
        }
        println!("  unchecked tests: {:?}", unchecked(tests));
        assert_eq!(missed, 0, "{name} covers every line");
    }
    assert!(
        suite_accepted(&agent),
        "the agent suite checks in every test"
    );
    assert!(!suite_accepted(&vacuous), "the vacuous suite is refused");
    println!("contract: m1-covered-not-checked same coverage, only one suite checks OK");
}
