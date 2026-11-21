//! Runs every m2 demo bin and reads its contract line back.

use std::process::Command;

fn last_line(exe: &str) -> String {
    let out = Command::new(exe).output().expect("bin runs");
    let stdout = String::from_utf8(out.stdout).expect("utf8 stdout");
    assert!(out.status.success(), "{exe} failed:\n{stdout}");
    stdout.lines().last().expect("a line").to_string()
}

#[test]
fn every_bin_ends_with_its_contract_line() {
    for exe in [
        env!("CARGO_BIN_EXE_m2_mutant"),
        env!("CARGO_BIN_EXE_m2_kill"),
        env!("CARGO_BIN_EXE_m2_equivalent"),
        env!("CARGO_BIN_EXE_m2_agent_suite"),
        env!("CARGO_BIN_EXE_m2_diff_scope"),
    ] {
        let last = last_line(exe);
        assert!(last.starts_with("contract: m2-"), "{last}");
        assert!(last.ends_with(" OK"), "{last}");
    }
}
