//! Runs every m3 demo bin and reads its contract line back.

use std::process::Command;

fn last_line(bin: &str, args: &[&str]) -> String {
    let out = Command::new(bin).args(args).output().expect("bin runs");
    let stdout = String::from_utf8(out.stdout).expect("utf8 stdout");
    assert!(out.status.success(), "{bin} failed:\n{stdout}");
    stdout
        .lines()
        .last()
        .expect("at least one line")
        .to_string()
}

fn assert_contract(last: &str) {
    assert!(last.starts_with("contract: "), "last line was: {last}");
    assert!(last.ends_with(" OK"), "last line was: {last}");
}

#[test]
fn m3_props_prints_its_contract_line() {
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_props"), &[]));
}

#[test]
fn m3_shrink_prints_its_contract_line() {
    let dir = env!("CARGO_TARGET_TMPDIR");
    let file = format!("{dir}/m3-shrink-test-regressions.txt");
    let _ = std::fs::remove_file(&file);
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_shrink"), &[&file]));
    let saved = std::fs::read_to_string(&file).expect("regression file");
    assert!(
        saved.contains("# shrinks to (0, 70697745951424350, 0)"),
        "{saved}"
    );
}

#[test]
fn m3_shrink_default_path_works() {
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_shrink"), &[]));
}

#[test]
fn m3_replay_prints_its_contract_line() {
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_replay"), &[]));
}

#[test]
fn m3_named_test_gate_prints_its_contract_line() {
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_named_test_gate"), &[]));
}

#[test]
fn m3_vacuous_contract_prints_its_contract_line() {
    assert_contract(&last_line(env!("CARGO_BIN_EXE_m3_vacuous_contract"), &[]));
}

#[test]
fn committed_regression_file_matches_the_run() {
    let committed = include_str!("../proptest-regressions/clamp-escape.txt");
    assert!(committed.contains("# shrinks to (0, 70697745951424350, 0)"));
}
