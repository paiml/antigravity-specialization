//! Every demo function on the saved runs, and one falsifier per demo.
//! These live outside `--lib` on purpose: mutation runs score the unit tests
//! only, and these tests replay source files byte for byte.

use m2::demos::*;
use m2::{agy_run_dir, mutants_dir};
use std::fs;
use std::path::Path;
use std::path::PathBuf;

const AGENT: &str = include_str!("../src/agent_shipping.rs");
const BULK: &str = include_str!("../src/bulk.rs");
const LISTS: [&str; 4] = ["caught.txt", "missed.txt", "timeout.txt", "unviable.txt"];

/// A scratch copy of a saved run with one list replaced.
fn scratch(test: &str, files: &[(&str, String)]) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("m2-demos-{test}-{}", std::process::id()));
    for (rel, body) in files {
        let path = dir.join(rel);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, body).unwrap();
    }
    dir
}

fn real(rel: &str) -> String {
    fs::read_to_string(mutants_dir().join(rel)).unwrap()
}

fn run_files(prefix: &str, from: &str) -> Vec<(String, String)> {
    LISTS
        .iter()
        .map(|l| (format!("{prefix}/{l}"), real(&format!("{from}/{l}"))))
        .collect()
}

fn as_refs(v: &[(String, String)]) -> Vec<(&str, String)> {
    v.iter().map(|(a, b)| (a.as_str(), b.clone())).collect()
}

#[test]
fn every_demo_holds_on_the_saved_runs() {
    let dir = mutants_dir();
    assert!(what_a_mutant_is(&dir).unwrap().ok);
    assert!(kill_the_survivor(&dir).unwrap().ok);
    assert!(equivalent_mutants(&dir).unwrap().ok);
    assert!(agent_suite(&dir, &agy_run_dir(), AGENT).unwrap().ok);
    assert!(diff_scope(&dir, BULK).unwrap().ok);
}

#[test]
fn a_suite_with_no_survivor_is_not_the_weak_suite_claim() {
    let files = run_files("price-weak", "price-kill");
    let dir = scratch("weak", &as_refs(&files));
    let r = what_a_mutant_is(&dir).unwrap();
    assert!(!r.ok && r.text.contains("ACCEPTED"));
}

#[test]
fn a_kill_run_with_a_survivor_is_refused() {
    let mut files = run_files("price-weak", "price-weak");
    files.extend(run_files("price-kill", "price-weak"));
    let dir = scratch("kill", &as_refs(&files));
    assert!(!kill_the_survivor(&dir).unwrap().ok);
}

#[test]
fn a_bogus_equivalent_claim_is_refused() {
    let mut files = run_files("cap", "cap");
    files.push((
        "cap/equivalents.txt".into(),
        "src/cap.rs:9:5: replace cap_percent -> u8 with 0 | made up\n".into(),
    ));
    let dir = scratch("equivalent", &as_refs(&files));
    let r = equivalent_mutants(&dir).unwrap();
    assert!(!r.ok && r.text.ends_with("REFUSED\n"));
}

#[test]
fn a_replay_that_differs_is_refused() {
    let r = agent_suite(&mutants_dir(), &agy_run_dir(), "not the agent file\n").unwrap();
    assert!(!r.ok && r.text.contains("DIFFERS"));
}

#[test]
fn a_reader_that_disagrees_with_the_tool_is_refused() {
    let mut files = run_files("diff-scope/full", "diff-scope/full");
    files.extend(
        LISTS
            .iter()
            .map(|l| (format!("diff-scope/in-diff/{l}"), String::new())),
    );
    files.push((
        "diff-scope/change.diff".into(),
        real("diff-scope/change.diff"),
    ));
    let dir = scratch("diff-scope", &as_refs(&files));
    let r = diff_scope(&dir, BULK).unwrap();
    assert!(!r.ok && r.text.contains("DISAGREE"));
}

#[test]
fn a_missing_file_is_an_error_not_a_pass() {
    let empty = Path::new("/nonexistent/m2");
    assert!(what_a_mutant_is(empty).is_err());
    assert!(kill_the_survivor(empty).is_err());
    assert!(equivalent_mutants(empty).is_err());
    assert!(agent_suite(empty, empty, AGENT).is_err());
    assert!(diff_scope(empty, BULK).is_err());
}
