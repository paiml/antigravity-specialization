//! Runs every demo bin and reads its contract line back.

use std::process::Command;

fn last_line(bin: &str) -> String {
    let out = Command::new(bin).output().expect("bin runs");
    assert!(out.status.success(), "{bin} failed: {out:?}");
    let stdout = String::from_utf8(out.stdout).expect("utf8 stdout");
    stdout
        .lines()
        .last()
        .expect("at least one line")
        .to_string()
}

#[test]
fn every_demo_bin_ends_with_its_contract_line() {
    let bins = [
        env!("CARGO_BIN_EXE_m6_judge"),
        env!("CARGO_BIN_EXE_m6_tally"),
        env!("CARGO_BIN_EXE_m6_mutant_list"),
        env!("CARGO_BIN_EXE_m6_receipt"),
    ];
    for bin in bins {
        let last = last_line(bin);
        assert!(last.starts_with("contract: m6-"), "{bin}: {last}");
        assert!(last.ends_with(" OK"), "{bin}: {last}");
    }
}
