//! Lesson 1.1, cold open: green CI and 100% line coverage, then the mutants.
//!
//! An agent (agy, gemini-4-neon-high) was asked to bring a crate with no tests
//! to 100% line coverage. Its run is recorded in `fixtures/agy-runs/m1-cold-open/`
//! and the numbers below were measured on a build host with `cargo llvm-cov` and
//! `cargo mutants`. This bin only reads them back.
//!
//! Provable contract: the recorded agent suite covers every line of its crate,
//! catches more mutants than no tests at all, and still leaves at least one
//! mutant alive, so 100% line coverage is not "every change is caught".

use m1::measured::{llvm_cov_lines, mutants_summary, percent};

const COV_BEFORE: &str =
    include_str!("../../../fixtures/agy-runs/m1-cold-open/measured/llvm-cov-before.txt");
const COV_AFTER: &str =
    include_str!("../../../fixtures/agy-runs/m1-cold-open/measured/llvm-cov-after.txt");
const MUT_BEFORE: &str =
    include_str!("../../../fixtures/agy-runs/m1-cold-open/measured/mutants-before.txt");
const MUT_AFTER: &str =
    include_str!("../../../fixtures/agy-runs/m1-cold-open/measured/mutants-after.txt");

fn main() {
    println!("recorded run: fixtures/agy-runs/m1-cold-open");
    let (lines_b, missed_b) = llvm_cov_lines(COV_BEFORE).expect("before: TOTAL row");
    let (lines, missed) = llvm_cov_lines(COV_AFTER).expect("after: TOTAL row");
    let before = mutants_summary(MUT_BEFORE).expect("before: mutants summary");
    let after = mutants_summary(MUT_AFTER).expect("after: mutants summary");

    println!(
        "no tests:    lines {}/{} ({}%), mutants caught {} of {}",
        lines_b - missed_b,
        lines_b,
        percent(lines_b - missed_b, lines_b),
        before.caught,
        before.viable()
    );
    println!(
        "agent suite: lines {}/{} ({}%), mutants caught {} of {}",
        lines - missed,
        lines,
        percent(lines - missed, lines),
        after.caught,
        after.viable()
    );
    for survivor in MUT_AFTER.lines().filter(|l| l.starts_with("MISSED")) {
        println!("survivor: {survivor}");
    }

    assert_eq!(missed, 0, "the agent suite covers every line");
    assert_eq!(before.caught, 0, "no tests catch nothing");
    assert!(
        after.caught > before.caught,
        "the agent suite catches mutants"
    );
    assert!(after.missed > 0, "and at least one mutant survives");
    println!(
        "contract: m1-cold-open 100% line coverage, {} of {} mutants still alive OK",
        after.missed,
        after.viable()
    );
}
