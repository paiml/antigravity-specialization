//! m6_mutant_list: review the tests, not the code.
//!
//! Provable contract: `cargo mutants` caught every mutant of the subject patch, yet two of
//! its tests assert nothing; the review handed the mutant list says the score missed them,
//! and the review without it never mentions mutants.

use m6::fixtures::{REVIEW_AUTHOR, REVIEW_WITH_MUTANTS, SUBJECT_MUTANTS, SUBJECT_PATCH};
use m6::review::{caught_vacuous, mentions_mutants, mutants_summary, parse_review};

fn main() {
    let (tested, caught) = mutants_summary(SUBJECT_MUTANTS).expect("recorded summary line");
    let empty_tests = SUBJECT_PATCH.matches("let _ = apply_discount").count();
    println!("cargo mutants on the subject: {tested} tested, {caught} caught");
    println!("calls whose result is thrown away in the tests: {empty_tests}");
    let without = parse_review(REVIEW_AUTHOR).expect("recorded review");
    let with = parse_review(REVIEW_WITH_MUTANTS).expect("recorded review");
    for (label, r) in [("without the list", &without), ("with the list", &with)] {
        println!(
            "{label}: verdict={} caught_vacuous={} mentions_mutants={}",
            r.verdict.word(),
            caught_vacuous(r),
            mentions_mutants(r)
        );
    }
    assert_eq!((tested, caught), (6, 6));
    assert_eq!(empty_tests, 8);
    assert!(caught_vacuous(&without) && caught_vacuous(&with));
    assert!(!mentions_mutants(&without));
    assert!(mentions_mutants(&with));
    println!("contract: m6-mutant-list a 6/6 mutant score hid two empty tests and only the review with the list said so OK");
}
