//! The verdict receipt (`m6_receipt`).
//!
//! A receipt is plain text, one field per line:
//!
//! ```text
//! subject: <what was judged>
//! head: <40-hex git object id of what was judged>
//! gate fmt: PASS <evidence>
//! ... one line per gate in GATES, each exactly once ...
//! verdict: ACCEPT|REFUSE
//! ```
//!
//! Rules: every gate in [`GATES`] appears exactly once with PASS, FAIL or NOT_RUN.
//! The verdict is ACCEPT only when every gate is PASS. A NOT_RUN gate is not a pass.
//! A receipt that breaks a rule is refused, whatever its verdict says.

use crate::review::Verdict;

/// The gates every receipt must carry, in the order they are written.
pub const GATES: [&str; 7] = [
    "fmt", "clippy", "test", "contract", "mutants", "coverage", "review",
];

/// The state of one gate.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    /// The gate ran and passed.
    Pass,
    /// The gate ran and failed.
    Fail,
    /// The gate was not run. Never counts as a pass.
    NotRun,
}

impl Status {
    fn word(self) -> &'static str {
        match self {
            Status::Pass => "PASS",
            Status::Fail => "FAIL",
            Status::NotRun => "NOT_RUN",
        }
    }

    fn parse(word: &str) -> Option<Status> {
        match word {
            "PASS" => Some(Status::Pass),
            "FAIL" => Some(Status::Fail),
            "NOT_RUN" => Some(Status::NotRun),
            _ => None,
        }
    }
}

/// One gate result: name, status, evidence (a command and its output, in words).
pub type Gate<'a> = (&'a str, Status, &'a str);

/// Why a receipt is refused.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ReceiptError {
    /// A required field or gate line is absent.
    Missing(String),
    /// A field or gate line appears twice.
    Duplicate(String),
    /// A line that is not a known field.
    Unknown(String),
    /// A gate status that is not PASS, FAIL or NOT_RUN.
    BadStatus(String),
    /// The head is not 40 lowercase hex characters.
    BadHead(String),
    /// The verdict word is neither ACCEPT nor REFUSE.
    BadVerdict(String),
    /// The written verdict is not the one the gates give.
    WrongVerdict {
        /// What the receipt says.
        written: Verdict,
        /// What the gates give.
        gates_give: Verdict,
    },
}

/// A receipt that passed every rule.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Receipt {
    /// What was judged.
    pub subject: String,
    /// The git object id of what was judged (a commit or a patch file).
    pub head: String,
    /// Status per gate, in [`GATES`] order.
    pub gates: Vec<Status>,
    /// The verdict, equal to what the gates give.
    pub verdict: Verdict,
}

/// The verdict a list of gate states gives: ACCEPT only when all PASS.
pub fn verdict_of(states: &[Status]) -> Verdict {
    if !states.is_empty() && states.iter().all(|s| *s == Status::Pass) {
        Verdict::Accept
    } else {
        Verdict::Refuse
    }
}

/// Write a receipt. The verdict is computed from the gates, never passed in.
pub fn write_receipt(subject: &str, head: &str, gates: &[Gate]) -> String {
    let mut out = format!("subject: {subject}\nhead: {head}\n");
    for (name, status, evidence) in gates {
        out.push_str(&format!("gate {name}: {} {evidence}\n", status.word()));
    }
    let states: Vec<Status> = gates.iter().map(|g| g.1).collect();
    out.push_str(&format!("verdict: {}\n", verdict_of(&states).word()));
    out
}

fn set_once(slot: &mut Option<String>, key: &str, value: &str) -> Result<(), ReceiptError> {
    if slot.is_some() {
        return Err(ReceiptError::Duplicate(key.to_string()));
    }
    *slot = Some(value.trim().to_string());
    Ok(())
}

fn gate_line(rest: &str, gates: &mut [Option<Status>]) -> Result<(), ReceiptError> {
    let (name, value) = rest
        .split_once(':')
        .ok_or_else(|| ReceiptError::Unknown(format!("gate {rest}")))?;
    let idx = GATES
        .iter()
        .position(|g| *g == name)
        .ok_or_else(|| ReceiptError::Unknown(format!("gate {name}")))?;
    let word = value.split_whitespace().next().unwrap_or("");
    let status = Status::parse(word).ok_or_else(|| ReceiptError::BadStatus(word.to_string()))?;
    if gates[idx].is_some() {
        return Err(ReceiptError::Duplicate(format!("gate {name}")));
    }
    gates[idx] = Some(status);
    Ok(())
}

/// The raw fields of a receipt, each seen at most once.
#[derive(Default)]
struct Fields {
    subject: Option<String>,
    head: Option<String>,
    verdict: Option<String>,
    gates: Vec<Option<Status>>,
}

fn read_line(line: &str, f: &mut Fields) -> Result<(), ReceiptError> {
    if let Some(v) = line.strip_prefix("subject:") {
        return set_once(&mut f.subject, "subject", v);
    }
    if let Some(v) = line.strip_prefix("head:") {
        return set_once(&mut f.head, "head", v);
    }
    if let Some(v) = line.strip_prefix("verdict:") {
        return set_once(&mut f.verdict, "verdict", v);
    }
    match line.strip_prefix("gate ") {
        Some(rest) => gate_line(rest, &mut f.gates),
        None => Err(ReceiptError::Unknown(line.to_string())),
    }
}

fn checked_head(head: Option<String>) -> Result<String, ReceiptError> {
    let head = head.ok_or_else(|| ReceiptError::Missing("head".into()))?;
    let is_hex = |c: char| c.is_ascii_digit() || ('a'..='f').contains(&c);
    if head.len() != 40 || !head.chars().all(is_hex) {
        return Err(ReceiptError::BadHead(head));
    }
    Ok(head)
}

fn written_verdict(verdict: Option<&str>) -> Result<Verdict, ReceiptError> {
    match verdict {
        Some("ACCEPT") => Ok(Verdict::Accept),
        Some("REFUSE") => Ok(Verdict::Refuse),
        Some(other) => Err(ReceiptError::BadVerdict(other.to_string())),
        None => Err(ReceiptError::Missing("verdict".into())),
    }
}

/// Check a receipt against every rule. Refused receipts say why.
pub fn check_receipt(text: &str) -> Result<Receipt, ReceiptError> {
    let mut f = Fields {
        gates: vec![None; GATES.len()],
        ..Fields::default()
    };
    for line in text.lines().filter(|l| !l.trim().is_empty()) {
        read_line(line, &mut f)?;
    }
    let subject = f
        .subject
        .ok_or_else(|| ReceiptError::Missing("subject".into()))?;
    let head = checked_head(f.head)?;
    let states = GATES
        .iter()
        .zip(&f.gates)
        .map(|(name, s)| s.ok_or_else(|| ReceiptError::Missing(format!("gate {name}"))))
        .collect::<Result<Vec<_>, _>>()?;
    let written = written_verdict(f.verdict.as_deref())?;
    let gates_give = verdict_of(&states);
    if written != gates_give {
        return Err(ReceiptError::WrongVerdict {
            written,
            gates_give,
        });
    }
    Ok(Receipt {
        subject,
        head,
        gates: states,
        verdict: written,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const HEAD: &str = "0123456789abcdef0123456789abcdef01234567";

    fn all(status: Status) -> Vec<Gate<'static>> {
        GATES.iter().map(|g| (*g, status, "evidence")).collect()
    }

    #[test]
    fn all_pass_accepts_and_round_trips() {
        let text = write_receipt("demo", HEAD, &all(Status::Pass));
        assert!(text.ends_with("verdict: ACCEPT\n"));
        let r = check_receipt(&text).unwrap();
        assert_eq!(r.verdict, Verdict::Accept);
        assert_eq!((r.subject.as_str(), r.head.as_str()), ("demo", HEAD));
        assert_eq!(r.gates.len(), GATES.len());
    }

    #[test]
    fn one_fail_or_not_run_refuses() {
        for bad in [Status::Fail, Status::NotRun] {
            let mut gates = all(Status::Pass);
            gates[6].1 = bad;
            let text = write_receipt("demo", HEAD, &gates);
            assert_eq!(check_receipt(&text).unwrap().verdict, Verdict::Refuse);
        }
        assert_eq!(verdict_of(&[]), Verdict::Refuse);
    }

    #[test]
    fn a_hand_edited_verdict_is_refused() {
        let mut gates = all(Status::Pass);
        gates[4].1 = Status::Fail;
        let text = write_receipt("demo", HEAD, &gates).replace("REFUSE", "ACCEPT");
        assert_eq!(
            check_receipt(&text),
            Err(ReceiptError::WrongVerdict {
                written: Verdict::Accept,
                gates_give: Verdict::Refuse
            })
        );
    }

    #[test]
    fn a_missing_gate_line_is_refused() {
        let text = write_receipt("demo", HEAD, &all(Status::Pass));
        let cut: String = text
            .lines()
            .filter(|l| !l.starts_with("gate mutants:"))
            .map(|l| format!("{l}\n"))
            .collect();
        assert_eq!(
            check_receipt(&cut),
            Err(ReceiptError::Missing("gate mutants".into()))
        );
    }

    #[test]
    fn every_other_broken_receipt_is_refused() {
        let good = write_receipt("demo", HEAD, &all(Status::Pass));
        let cases: Vec<(String, ReceiptError)> = vec![
            (
                format!("{good}head: {HEAD}\n"),
                ReceiptError::Duplicate("head".into()),
            ),
            (
                format!("{good}gate fmt: PASS again\n"),
                ReceiptError::Duplicate("gate fmt".into()),
            ),
            (
                format!("{good}gate lint: PASS\n"),
                ReceiptError::Unknown("gate lint".into()),
            ),
            (
                format!("{good}gate fmt PASS\n"),
                ReceiptError::Unknown("gate fmt PASS".into()),
            ),
            (
                format!("{good}note: hi\n"),
                ReceiptError::Unknown("note: hi".into()),
            ),
            (
                good.replace("gate fmt: PASS", "gate fmt: GREEN"),
                ReceiptError::BadStatus("GREEN".into()),
            ),
            (
                good.replace("gate fmt: PASS evidence", "gate fmt:"),
                ReceiptError::BadStatus(String::new()),
            ),
            (
                good.replace(HEAD, "abc"),
                ReceiptError::BadHead("abc".into()),
            ),
            (
                good.replace(HEAD, &HEAD.to_uppercase()),
                ReceiptError::BadHead(HEAD.to_uppercase()),
            ),
            (
                good.replace("verdict: ACCEPT", "verdict: SHIP"),
                ReceiptError::BadVerdict("SHIP".into()),
            ),
            (
                good.replace("verdict: ACCEPT\n", ""),
                ReceiptError::Missing("verdict".into()),
            ),
            (
                good.replace("subject: demo\n", ""),
                ReceiptError::Missing("subject".into()),
            ),
            (
                good.replace(&format!("head: {HEAD}\n"), ""),
                ReceiptError::Missing("head".into()),
            ),
        ];
        for (text, want) in cases {
            assert_eq!(check_receipt(&text), Err(want), "receipt:\n{text}");
        }
    }
}
