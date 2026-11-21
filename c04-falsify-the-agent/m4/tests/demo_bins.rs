//! Runs every m4 demo bin and reads its contract line back.

use std::process::Command;

fn run(bin: &str) -> String {
    let out = Command::new(bin).output().expect("demo bin runs");
    assert!(out.status.success(), "{bin} exited {:?}", out.status);
    String::from_utf8(out.stdout).expect("utf8 stdout")
}

fn assert_contract(stdout: &str, name: &str) {
    let last = stdout.lines().last().expect("at least one line");
    assert!(
        last.starts_with(&format!("contract: {name} ")),
        "last line: {last}"
    );
    assert!(last.ends_with(" OK"), "last line: {last}");
}

#[test]
fn empty_gate_shows_the_vacuous_green() {
    let out = run(env!("CARGO_BIN_EXE_m4_empty_gate"));
    assert!(out.contains("empty report: 0 tests, pass rate 1.00, gate says PASS"));
    assert!(out.contains("red report:   3 tests, pass rate 0.67, gate says FAIL"));
    assert_contract(&out, "m4-empty-gate");
}

#[test]
fn falsifier_catches_then_clears() {
    let out = run(env!("CARGO_BIN_EXE_m4_falsifier"));
    assert!(out.contains("falsifier vs gate with no floor: CannotSayNo"));
    assert!(out.contains("falsifier vs gate with floor 4: RefusesEmpty"));
    assert!(out.contains("floor gate on green: 5 tests -> true"));
    assert_contract(&out, "m4-falsifier");
}

#[test]
fn waiver_levers_reads_the_recorded_pv_runs() {
    let out = run(env!("CARGO_BIN_EXE_m4_waiver_levers"));
    assert!(out.contains("--severity error"));
    assert_contract(&out, "m4-waiver-levers");
}

#[test]
fn referee_accepts_agy_and_refuses_planted() {
    let out = run(env!("CARGO_BIN_EXE_m4_referee"));
    assert!(out.contains("referee hits [\"gate.floor\", \"gate.sh\"]"));
    assert_contract(&out, "m4-referee");
}
