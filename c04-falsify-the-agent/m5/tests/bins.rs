//! Runs every demo bin and reads its contract line back.

use std::process::Command;

fn last_line(exe: &str) -> String {
    let out = Command::new(exe).output().expect("bin runs");
    assert!(out.status.success(), "{exe} exited {:?}", out.status);
    let stdout = String::from_utf8(out.stdout).expect("utf8 stdout");
    stdout
        .lines()
        .last()
        .expect("at least one line")
        .to_string()
}

fn assert_contract(exe: &str) {
    let last = last_line(exe);
    assert!(
        last.starts_with("contract: ") && last.ends_with(" OK"),
        "{exe}: {last}"
    );
}

#[test]
fn bin_curl_is_not_a_test() {
    assert_contract(env!("CARGO_BIN_EXE_m5_curl_is_not_a_test"));
}

#[test]
fn bin_control_contract() {
    assert_contract(env!("CARGO_BIN_EXE_m5_control_contract"));
}

#[test]
fn bin_drive_every_control() {
    assert_contract(env!("CARGO_BIN_EXE_m5_drive_every_control"));
}

#[test]
fn bin_read_the_result_back() {
    assert_contract(env!("CARGO_BIN_EXE_m5_read_the_result_back"));
}
