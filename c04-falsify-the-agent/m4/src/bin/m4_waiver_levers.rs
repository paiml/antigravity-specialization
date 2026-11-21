//! m4_waiver_levers: a gate has two states.
//!
//! Provable contract: in the recorded pv lint runs, `--severity error` hides
//! the one finding without a trace, `--suppress-rule` hides it but counts it,
//! `--strict` promotes it to an error, and that error still exits 0.

use m4::lint::{self, Lever};

const RUNS: &str = include_str!("../../fixtures/pv-lint-levers.txt");

fn main() {
    let runs = lint::parse_transcript(RUNS);
    assert_eq!(runs.len(), 4, "four recorded pv lint runs");
    let base = runs[0].summary.expect("base summary");
    for run in &runs {
        let s = run.summary.expect("every run has a summary");
        println!(
            "{:<70} shown {} hidden {} vanished {} exit {:?}",
            run.command,
            s.visible(),
            lint::hidden(&base, &s),
            lint::vanished(&base, &s),
            run.exit
        );
    }
    let [plain, severity, strict, suppress] = [0, 1, 2, 3].map(|i| &runs[i]);
    assert!(lint::levers(&plain.command).is_empty());
    assert_eq!(base.visible(), 1, "one finding to start");
    let sev = severity.summary.unwrap();
    assert_eq!(lint::levers(&severity.command), vec![Lever::Hides]);
    assert_eq!(
        (lint::hidden(&base, &sev), lint::vanished(&base, &sev)),
        (1, 1)
    );
    let sup = suppress.summary.unwrap();
    assert!(lint::levers(&suppress.command).contains(&Lever::Hides));
    assert_eq!(
        (lint::hidden(&base, &sup), lint::vanished(&base, &sup)),
        (1, 0)
    );
    assert_eq!(lint::levers(&strict.command), vec![Lever::Promotes]);
    assert_eq!(strict.summary.unwrap().errors, 1);
    assert!(lint::exit_ignores_errors(strict), "exit 0 with 1 error");
    println!(
        "contract: m4-waiver-levers names the hiding levers and the exit that ignores an error OK"
    );
}
