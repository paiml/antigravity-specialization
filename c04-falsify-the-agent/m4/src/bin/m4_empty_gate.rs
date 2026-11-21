//! m4_empty_gate: the gate that cannot say no.
//!
//! Provable contract: the pass-rate gate with no floor passes an empty test
//! report and refuses the recorded red report; the green on empty is the defect.

use m4::{gate, report};

const EMPTY: &str = include_str!("../../fixtures/report-empty.txt");
const RED: &str = include_str!("../../fixtures/report-red.txt");

fn main() {
    let empty = report::parse(EMPTY);
    let red = report::parse(RED);
    println!(
        "empty report: {} tests, pass rate {:.2}, gate says {}",
        empty.total(),
        gate::pass_rate(&empty),
        verdict(gate::no_floor(&empty, 1.0))
    );
    println!(
        "red report:   {} tests, pass rate {:.2}, gate says {}",
        red.total(),
        gate::pass_rate(&red),
        verdict(gate::no_floor(&red, 1.0))
    );
    assert_eq!(empty.total(), 0);
    assert!(gate::no_floor(&empty, 1.0), "the defect: empty passes");
    assert!(!gate::no_floor(&red, 1.0));
    println!("contract: m4-empty-gate passes an empty report and refuses a red one OK");
}

fn verdict(pass: bool) -> &'static str {
    if pass {
        "PASS"
    } else {
        "FAIL"
    }
}
