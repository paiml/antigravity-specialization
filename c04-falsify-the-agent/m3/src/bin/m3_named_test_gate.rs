//! The test a contract names must exist.
//!
//! Provable contract: the agent's recorded contract (run `m3-named-test`) cites only
//! tests that exist and is accepted; a contract citing a test that is not in the source
//! is refused here, even though `pv lint --strict-test-binding --strict` ends that run
//! with `Result: PASS` and exit 0.

use m3::lint_gate::{accept, cited_tests, read};
use std::path::Path;

const LINT: [&str; 6] = [
    "lint",
    "contracts",
    "--strict-test-binding",
    "--strict",
    "-f",
    "json",
];

fn main() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("fixtures");
    let agent = root.join("agent/m3-named-test");
    let dangling = root.join("hand/dangling");

    let yaml =
        std::fs::read_to_string(agent.join("contracts/clamp-v1.yaml")).expect("agent contract");
    let tests = cited_tests(&yaml);
    let ids = yaml.matches("- id: FALSIFY-").count();
    println!(
        "agent contract: {ids} falsification ids cite {} distinct test(s): {tests:?}",
        tests.len()
    );
    assert_eq!((ids, tests.len()), (3, 1));

    let agent_ok = judge(&agent);
    assert!(agent_ok, "every test the agent cited exists");

    let text = m3::pv::run(&dangling, &LINT[..4]).expect("pv runs");
    let last = text.stdout.lines().last().unwrap_or_default().to_string();
    println!(
        "hand-written dangling fixture, pv text mode: last line {last:?}, exit {}",
        text.exit
    );
    let dangling_ok = judge(&dangling);
    assert!(
        !dangling_ok,
        "a cited test that is not in the source is refused"
    );

    println!("contract: m3-named-test-gate accepts the agent's real test names and refuses a dangling one OK");
}

fn judge(dir: &Path) -> bool {
    let run = m3::pv::run(dir, &LINT).expect("pv runs");
    let b = read(&run.stdout).expect("pv lint JSON");
    let ok = accept(b);
    let name = dir.file_name().unwrap_or_default().to_string_lossy();
    println!(
        "{name}: pv passed={} refs={} missing={} (pv exit {}) -> {}",
        b.passed,
        b.total_refs,
        b.missing,
        run.exit,
        if ok { "ACCEPT" } else { "REFUSE" }
    );
    ok
}
