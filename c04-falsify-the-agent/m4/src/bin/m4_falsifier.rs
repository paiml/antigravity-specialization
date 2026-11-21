//! m4_falsifier: write the falsifier first.
//!
//! Provable contract: the falsifier (the empty report) catches the gate with
//! no floor, and the gate with a floor refuses empty and red, and passes green.

use m4::falsifier::{falsify, Verdict};
use m4::{gate, report};

const EMPTY: &str = include_str!("../../fixtures/report-empty.txt");
const RED: &str = include_str!("../../fixtures/report-red.txt");
const GREEN: &str = include_str!("../../fixtures/report-green.txt");

/// The floor: the arena's `gate.floor`.
const FLOOR: usize = 4;

fn main() {
    let before = falsify(&|r| gate::no_floor(r, 1.0));
    let after = falsify(&|r| gate::with_floor(r, 1.0, FLOOR));
    println!("falsifier vs gate with no floor: {before:?}");
    println!("falsifier vs gate with floor {FLOOR}: {after:?}");
    let [empty, red, green] = [EMPTY, RED, GREEN].map(report::parse);
    for (name, r) in [("empty", empty), ("red", red), ("green", green)] {
        let pass = gate::with_floor(&r, 1.0, FLOOR);
        println!("floor gate on {name}: {} tests -> {}", r.total(), pass);
    }
    assert_eq!(before, Verdict::CannotSayNo);
    assert_eq!(after, Verdict::RefusesEmpty);
    assert!(!gate::with_floor(&empty, 1.0, FLOOR));
    assert!(!gate::with_floor(&red, 1.0, FLOOR));
    assert!(gate::with_floor(&green, 1.0, FLOOR));
    println!(
        "contract: m4-falsifier catches the floorless gate and the floor gate passes only green OK"
    );
}
