//! Runs every m1 demo bin and reads its output back.

use std::process::Command;

fn run(bin: &str) -> String {
    let out = Command::new(bin).output().expect("demo bin runs");
    assert!(out.status.success(), "{bin} exited {:?}", out.status);
    String::from_utf8(out.stdout).expect("utf8 stdout")
}

fn last_line(stdout: &str) -> &str {
    stdout.lines().last().expect("at least one line")
}

#[test]
fn cold_open_reads_the_recorded_numbers() {
    let s = run(env!("CARGO_BIN_EXE_m1_cold_open"));
    assert!(
        s.contains("no tests:    lines 0/28 (0%), mutants caught 0 of 29"),
        "{s}"
    );
    assert!(
        s.contains("agent suite: lines 52/52 (100%), mutants caught 28 of 29"),
        "{s}"
    );
    assert!(
        s.contains("survivor: MISSED   src/lib.rs:9:21: replace > with >="),
        "{s}"
    );
    assert_eq!(
        last_line(&s),
        "contract: m1-cold-open 100% line coverage, 1 of 29 mutants still alive OK"
    );
}

#[test]
fn vacuous_passes_the_wrong_body() {
    let s = run(env!("CARGO_BIN_EXE_m1_vacuous"));
    assert!(s.contains("vacuous check  on wrong body: PASS"), "{s}");
    assert!(s.contains("real check     on wrong body: FAIL"), "{s}");
    assert!(
        s.contains("wrong body at 50_000: 5000 (right: 2000)"),
        "{s}"
    );
    assert!(last_line(&s).starts_with("contract: m1-vacuous"));
}

#[test]
fn covered_not_checked_refuses_the_vacuous_suite() {
    let s = run(env!("CARGO_BIN_EXE_m1_covered_not_checked"));
    assert!(s.contains("unchecked tests: []"), "{s}");
    let refused =
        r#"unchecked tests: ["shipping_fee_runs", "member_discount_runs", "order_total_runs"]"#;
    assert!(s.contains(refused), "{s}");
    assert!(last_line(&s).starts_with("contract: m1-covered-not-checked"));
}

#[test]
fn test_floor_is_green_on_the_agent_fix_and_red_on_a_deletion() {
    let s = run(env!("CARGO_BIN_EXE_m1_test_floor"));
    assert!(
        s.contains("recorded agent fix           GREEN running 5"),
        "{s}"
    );
    let deleted =
        r#"hand-written: test deleted   RED   running 4 deleted ["tests::parses_seconds"]"#;
    assert!(s.contains(deleted), "{s}");
    assert!(s.contains(r#"ignored ["tests::parses_seconds"]"#), "{s}");
    assert!(last_line(&s).starts_with("contract: m1-test-floor"));
}
