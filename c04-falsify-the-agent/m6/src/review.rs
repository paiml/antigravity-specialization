//! Read a saved review and judge what it caught (`m6_judge`, `m6_mutant_list`).
//!
//! A review is plain text. Findings are lines holding `FINDING:`. The verdict is the
//! one line that reads `VERDICT: ACCEPT` or `VERDICT: REFUSE` (markdown bold and
//! backticks around it are ignored). No verdict line, or two, is not a review.

/// What a reviewer decided.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
    /// The reviewer would merge it.
    Accept,
    /// The reviewer would not merge it.
    Refuse,
}

impl Verdict {
    /// The word used in receipts.
    pub fn word(self) -> &'static str {
        match self {
            Verdict::Accept => "ACCEPT",
            Verdict::Refuse => "REFUSE",
        }
    }
}

/// A parsed review.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Review {
    /// Text after each `FINDING:` marker, in order.
    pub findings: Vec<String>,
    /// The single verdict.
    pub verdict: Verdict,
}

/// Why a text is not a review.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ReviewError {
    /// No `VERDICT:` line at all.
    NoVerdict,
    /// More than one `VERDICT:` line.
    TwoVerdicts,
    /// A `VERDICT:` line whose word is neither ACCEPT nor REFUSE.
    BadVerdict(String),
}

/// The two test functions whose assertions were removed in the review subject.
pub const VACUOUS_TESTS: [&str; 2] = [
    "full_or_excessive_discount_returns_zero",
    "rounds_down_to_whole_cents",
];

fn strip_marks(line: &str) -> &str {
    line.trim().trim_matches(|c| c == '*' || c == '`').trim()
}

/// Parse a saved review.
pub fn parse_review(text: &str) -> Result<Review, ReviewError> {
    let mut findings = Vec::new();
    let mut verdict = None;
    for line in text.lines() {
        if let Some((_, rest)) = line.split_once("FINDING:") {
            findings.push(rest.trim().to_string());
            continue;
        }
        let Some(word) = strip_marks(line).strip_prefix("VERDICT:") else {
            continue;
        };
        if verdict.is_some() {
            return Err(ReviewError::TwoVerdicts);
        }
        verdict = Some(match strip_marks(word) {
            "ACCEPT" => Verdict::Accept,
            "REFUSE" => Verdict::Refuse,
            other => return Err(ReviewError::BadVerdict(other.to_string())),
        });
    }
    let verdict = verdict.ok_or(ReviewError::NoVerdict)?;
    Ok(Review { findings, verdict })
}

/// True when some finding names one of the given test functions.
pub fn names_any(review: &Review, tests: &[&str]) -> bool {
    review
        .findings
        .iter()
        .any(|f| tests.iter().any(|t| f.contains(t)))
}

/// A review caught the vacuous tests only if it refuses AND a finding names one of them.
/// A refusal for some other reason does not count.
pub fn caught_vacuous(review: &Review) -> bool {
    review.verdict == Verdict::Refuse && names_any(review, &VACUOUS_TESTS)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_findings_and_a_bold_verdict() {
        let r = parse_review("intro\nFINDING: a\n- FINDING: b\n**VERDICT: REFUSE**\n").unwrap();
        assert_eq!(r.findings, vec!["a", "b"]);
        assert_eq!(r.verdict, Verdict::Refuse);
        assert_eq!(r.verdict.word(), "REFUSE");
        let a = parse_review("`VERDICT: ACCEPT`").unwrap();
        assert_eq!(a.verdict, Verdict::Accept);
        assert_eq!(a.verdict.word(), "ACCEPT");
    }

    #[test]
    fn refuses_text_that_is_not_a_review() {
        assert_eq!(parse_review("FINDING: x"), Err(ReviewError::NoVerdict));
        assert_eq!(
            parse_review("VERDICT: ACCEPT\nVERDICT: REFUSE"),
            Err(ReviewError::TwoVerdicts)
        );
        assert_eq!(
            parse_review("VERDICT: MAYBE"),
            Err(ReviewError::BadVerdict("MAYBE".into()))
        );
    }

    #[test]
    fn a_refusal_for_another_reason_did_not_catch_the_vacuous_test() {
        let other = parse_review("FINDING: style\nVERDICT: REFUSE").unwrap();
        assert!(!caught_vacuous(&other));
        let named = "FINDING: rounds_down_to_whole_cents asserts nothing\nVERDICT: ";
        let accepted = parse_review(&format!("{named}ACCEPT")).unwrap();
        assert!(names_any(&accepted, &VACUOUS_TESTS));
        assert!(!caught_vacuous(&accepted));
        let refused = parse_review(&format!("{named}REFUSE")).unwrap();
        assert!(caught_vacuous(&refused));
    }
}

/// Read the summary line of `cargo mutants` output: `(tested, caught)`.
/// Returns `None` when the output has no summary line.
pub fn mutants_summary(output: &str) -> Option<(usize, usize)> {
    let line = output.lines().find(|l| l.contains("mutants tested in"))?;
    let tested = line.split_whitespace().next()?.parse().ok()?;
    let caught = line
        .split_once(": ")?
        .1
        .split(", ")
        .find_map(|part| part.strip_suffix(" caught"))
        .map_or(Some(0), |n| n.trim().parse().ok())?;
    Some((tested, caught))
}

/// True when some finding talks about mutation testing.
pub fn mentions_mutants(review: &Review) -> bool {
    review
        .findings
        .iter()
        .any(|f| f.to_lowercase().contains("mutant"))
}

#[cfg(test)]
mod mutant_tests {
    use super::*;

    #[test]
    fn reads_the_cargo_mutants_summary() {
        let out = "Found 6 mutants to test\n6 mutants tested in 1s: 6 caught\n";
        assert_eq!(mutants_summary(out), Some((6, 6)));
        let mixed = "9 mutants tested in 2s: 2 missed, 7 caught";
        assert_eq!(mutants_summary(mixed), Some((9, 7)));
        assert_eq!(
            mutants_summary("3 mutants tested in 1s: 3 missed"),
            Some((3, 0))
        );
        assert_eq!(mutants_summary("no summary"), None);
        assert_eq!(mutants_summary("x mutants tested in 1s: 1 caught"), None);
        assert_eq!(mutants_summary("1 mutants tested in 1s"), None);
        assert_eq!(mutants_summary("2 mutants tested in 1s: y caught"), None);
    }

    #[test]
    fn spots_a_finding_about_mutants() {
        let yes = parse_review("FINDING: the Mutant score is 6/6\nVERDICT: REFUSE").unwrap();
        let no = parse_review("FINDING: style\nVERDICT: REFUSE").unwrap();
        assert!(mentions_mutants(&yes));
        assert!(!mentions_mutants(&no));
    }
}
