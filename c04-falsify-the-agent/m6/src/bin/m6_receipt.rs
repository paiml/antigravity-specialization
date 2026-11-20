//! m6_receipt: the capstone verdict receipt.
//!
//! Provable contract: both capstone receipts are rebuilt from their measured gates byte for
//! byte and pass every rule, both refuse (the agent patch on fmt alone, though its reviewer
//! accepted), and a receipt with a missing gate line or a hand-edited verdict is refused.

use m6::fixtures::{RECEIPT_AGENT, RECEIPT_SUBJECT};
use m6::receipt::{check_receipt, write_receipt, Gate, ReceiptError, Status};
use m6::review::Verdict;

/// git hash-object of fixtures/agy-runs/m6-capstone/patch.diff
const AGENT_HEAD: &str = "4afd7e8eb8a41a923f7169eb88b3b8d246b2b8d8";
/// git hash-object of fixtures/subject/vacuous.patch.diff
const SUBJECT_HEAD: &str = "40254d9ddb0a0e747d392318df569ec9032e3ca8";

const AGENT_GATES: [Gate; 7] = [
    (
        "fmt",
        Status::Fail,
        "cargo fmt -- --check exit 1: trailing blank line, src/lib.rs:55",
    ),
    (
        "clippy",
        Status::Pass,
        "cargo clippy --all-targets -- -D warnings exit 0",
    ),
    (
        "test",
        Status::Pass,
        "cargo test: 5 passed, 0 failed",
    ),
    (
        "contract",
        Status::Pass,
        "m6/contracts/discount-v1.yaml: pv lint PASS, obligations 0 problems, score 0.65",
    ),
    (
        "mutants",
        Status::Pass,
        "cargo mutants 27.1.0: 6 tested, 6 caught",
    ),
    (
        "coverage",
        Status::Pass,
        "cargo llvm-cov 0.9.1: lines 100.00%",
    ),
    (
        "review",
        Status::Pass,
        "claude-sonnet-5-5: VERDICT: ACCEPT (fixtures/reviews/m6-review-agent-patch)",
    ),
];

const SUBJECT_GATES: [Gate; 7] = [
    (
        "fmt",
        Status::Fail,
        "cargo fmt -- --check exit 1: trailing blank line, src/lib.rs:55",
    ),
    (
        "clippy",
        Status::Pass,
        "cargo clippy --all-targets -- -D warnings exit 0",
    ),
    (
        "test",
        Status::Pass,
        "cargo test: 5 passed, 0 failed",
    ),
    (
        "contract",
        Status::NotRun,
        "pv was not run against the subject tree",
    ),
    (
        "mutants",
        Status::Pass,
        "cargo mutants 27.1.0: 6 tested, 6 caught",
    ),
    (
        "coverage",
        Status::Pass,
        "cargo llvm-cov 0.9.1: lines 100.00%",
    ),
    (
        "review",
        Status::Fail,
        "quorum: seats=3 accept=0 refuse=3 no_verdict=0 decision=REFUSE (m6_tally)",
    ),
];

fn main() {
    let agent = write_receipt("agent patch, m6-capstone", AGENT_HEAD, &AGENT_GATES);
    let subject = write_receipt(
        "subject patch, two tests emptied",
        SUBJECT_HEAD,
        &SUBJECT_GATES,
    );
    print!("{agent}");
    print!("{subject}");
    assert_eq!(agent, RECEIPT_AGENT);
    assert_eq!(subject, RECEIPT_SUBJECT);
    let a = check_receipt(RECEIPT_AGENT).expect("agent receipt passes every rule");
    let s = check_receipt(RECEIPT_SUBJECT).expect("subject receipt passes every rule");
    assert_eq!((a.verdict, s.verdict), (Verdict::Refuse, Verdict::Refuse));

    let cut: String = RECEIPT_AGENT
        .lines()
        .filter(|l| !l.starts_with("gate fmt:"))
        .map(|l| format!("{l}\n"))
        .collect();
    let edited = RECEIPT_AGENT
        .replace("gate fmt: FAIL", "gate fmt: PASS")
        .replace("verdict: ACCEPT", "verdict: REFUSE");
    let flipped = RECEIPT_AGENT.replace("verdict: REFUSE", "verdict: ACCEPT");
    println!("fmt line removed: {:?}", check_receipt(&cut));
    println!("verdict flipped to ACCEPT: {:?}", check_receipt(&flipped));
    assert_eq!(
        check_receipt(&cut),
        Err(ReceiptError::Missing("gate fmt".into()))
    );
    assert!(matches!(
        check_receipt(&flipped),
        Err(ReceiptError::WrongVerdict { .. })
    ));
    assert!(matches!(
        check_receipt(&edited),
        Err(ReceiptError::WrongVerdict { .. })
    ));
    println!("contract: m6-receipt both capstone receipts refuse and a cut or edited receipt is refused OK");
}
