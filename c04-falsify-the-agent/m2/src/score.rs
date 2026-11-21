//! Reads the lists `cargo mutants` writes (`caught.txt`, `missed.txt`,
//! `timeout.txt`, `unviable.txt`) and gives an honest verdict.

use std::fs;
use std::path::Path;

/// One mutant as `cargo mutants` names it: `file:line:col: what`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Mutant {
    pub file: String,
    pub line: u32,
    pub col: u32,
    pub what: String,
}

impl Mutant {
    /// Parses one line of a `cargo mutants` list.
    pub fn parse(text: &str) -> Result<Mutant, String> {
        let bad = || format!("not a mutant line: {text:?}");
        let (file, rest) = text.split_once(':').ok_or_else(bad)?;
        let (line, rest) = rest.split_once(':').ok_or_else(bad)?;
        let (col, what) = rest.split_once(": ").ok_or_else(bad)?;
        let line = line.parse().map_err(|_| bad())?;
        let col = col.parse().map_err(|_| bad())?;
        if file.is_empty() || what.trim().is_empty() {
            return Err(bad());
        }
        Ok(Mutant {
            file: file.to_string(),
            line,
            col,
            what: what.to_string(),
        })
    }

    /// The mutant written back in the tool's own form.
    pub fn label(&self) -> String {
        format!("{}:{}:{}: {}", self.file, self.line, self.col, self.what)
    }
}

/// Parses a whole list; blank lines are skipped, a bad line is an error.
pub fn parse_list(text: &str) -> Result<Vec<Mutant>, String> {
    text.lines()
        .filter(|l| !l.trim().is_empty())
        .map(Mutant::parse)
        .collect()
}

/// The four outcome lists of one `cargo mutants` run.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Outcomes {
    pub caught: Vec<Mutant>,
    pub missed: Vec<Mutant>,
    pub timeout: Vec<Mutant>,
    pub unviable: Vec<Mutant>,
}

fn read_list(dir: &Path, name: &str) -> Result<Vec<Mutant>, String> {
    let path = dir.join(name);
    let text = fs::read_to_string(&path).map_err(|e| format!("{}: {e}", path.display()))?;
    parse_list(&text)
}

impl Outcomes {
    /// Loads a saved run. A missing list is an error: an absent receipt is not zero.
    pub fn load(dir: &Path) -> Result<Outcomes, String> {
        Ok(Outcomes {
            caught: read_list(dir, "caught.txt")?,
            missed: read_list(dir, "missed.txt")?,
            timeout: read_list(dir, "timeout.txt")?,
            unviable: read_list(dir, "unviable.txt")?,
        })
    }

    /// Mutants that built and ran: caught plus missed.
    pub fn tested(&self) -> usize {
        self.caught.len() + self.missed.len()
    }
}

/// Caught over caught plus missed. `None` when nothing was tested:
/// an empty run is not a 100% score.
pub fn kill_rate(caught: usize, missed: usize) -> Option<f64> {
    let tested = caught + missed;
    if tested == 0 {
        None
    } else {
        Some(caught as f64 / tested as f64)
    }
}

/// A survivor claimed to be equivalent, with the reason why.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Equivalent {
    pub mutant: String,
    pub reason: String,
}

/// Parses `<mutant label> | <reason>` lines.
pub fn parse_equivalents(text: &str) -> Result<Vec<Equivalent>, String> {
    text.lines()
        .filter(|l| !l.trim().is_empty())
        .map(|l| {
            let (m, r) = l
                .split_once(" | ")
                .ok_or_else(|| format!("no ' | reason' on: {l:?}"))?;
            Ok(Equivalent {
                mutant: m.trim().to_string(),
                reason: r.trim().to_string(),
            })
        })
        .collect()
}

/// Accept or refuse a test suite on its mutation run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Verdict {
    Accepted,
    Refused(String),
}

/// The honest verdict. Refused when nothing was tested, when a timeout is
/// counted, when an equivalent claim has no reason or matches no survivor, or
/// when any survivor is left that no claim explains.
pub fn judge(run: &Outcomes, equivalents: &[Equivalent]) -> Verdict {
    if run.tested() == 0 {
        return Verdict::Refused("no mutant was tested: an empty run proves nothing".into());
    }
    if !run.timeout.is_empty() {
        return Verdict::Refused(format!("{} timeout(s): not a kill", run.timeout.len()));
    }
    for eq in equivalents {
        if eq.reason.is_empty() {
            return Verdict::Refused(format!("equivalent claim with no reason: {}", eq.mutant));
        }
        if !run.missed.iter().any(|m| m.label() == eq.mutant) {
            return Verdict::Refused(format!(
                "equivalent claim matches no survivor: {}",
                eq.mutant
            ));
        }
    }
    let unexplained = run
        .missed
        .iter()
        .filter(|m| !equivalents.iter().any(|e| e.mutant == m.label()))
        .count();
    if unexplained > 0 {
        return Verdict::Refused(format!("{unexplained} survivor(s) alive"));
    }
    Verdict::Accepted
}

/// Formats a kill rate, or says it is not measured.
pub fn rate_text(rate: Option<f64>) -> String {
    match rate {
        Some(r) => format!("{:.1}%", r * 100.0),
        None => "not measured (0 tested)".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn m(what: &str) -> Mutant {
        Mutant::parse(&format!("m2/src/x.rs:3:7: {what}")).unwrap()
    }

    #[test]
    fn parses_and_relabels_a_mutant_line() {
        let line = "m2/src/price.rs:9:15: replace >= with < in line_total";
        let mu = Mutant::parse(line).unwrap();
        assert_eq!(mu.file, "m2/src/price.rs");
        assert_eq!((mu.line, mu.col), (9, 15));
        assert_eq!(mu.what, "replace >= with < in line_total");
        assert_eq!(mu.label(), line);
    }

    #[test]
    fn refuses_malformed_lines() {
        for bad in [
            "",
            "nocolon",
            "f:1",
            "f:1:2 no-space",
            "f:x:2: w",
            "f:1:y: w",
            ":1:2: w",
            "f:1:2:  ",
        ] {
            assert!(Mutant::parse(bad).is_err(), "{bad:?}");
        }
        assert!(parse_list("f:1:2: ok\n\nbad\n").is_err());
        assert_eq!(parse_list("f:1:2: ok\n\n").unwrap().len(), 1);
    }

    #[test]
    fn kill_rate_has_no_score_for_an_empty_run() {
        assert_eq!(kill_rate(0, 0), None);
        assert_eq!(kill_rate(3, 1), Some(0.75));
        assert_eq!(rate_text(None), "not measured (0 tested)");
        assert_eq!(rate_text(Some(0.75)), "75.0%");
    }

    #[test]
    fn judge_refuses_empty_timeouts_and_survivors() {
        assert!(matches!(
            judge(&Outcomes::default(), &[]),
            Verdict::Refused(_)
        ));
        let mut run = Outcomes {
            caught: vec![m("a")],
            ..Outcomes::default()
        };
        assert_eq!(judge(&run, &[]), Verdict::Accepted);
        run.timeout.push(m("t"));
        assert!(matches!(judge(&run, &[]), Verdict::Refused(r) if r.contains("timeout")));
        run.timeout.clear();
        run.missed.push(m("b"));
        assert_eq!(
            judge(&run, &[]),
            Verdict::Refused("1 survivor(s) alive".into())
        );
    }

    #[test]
    fn equivalent_claims_must_name_a_survivor_and_a_reason() {
        let run = Outcomes {
            caught: vec![m("a")],
            missed: vec![m("b")],
            ..Outcomes::default()
        };
        let good = parse_equivalents(&format!("{} | same result\n\n", m("b").label())).unwrap();
        assert_eq!(judge(&run, &good), Verdict::Accepted);
        let bogus = parse_equivalents(&format!("{} | made up", m("zzz").label())).unwrap();
        assert!(
            matches!(judge(&run, &bogus), Verdict::Refused(r) if r.contains("matches no survivor"))
        );
        let silent = vec![Equivalent {
            mutant: m("b").label(),
            reason: String::new(),
        }];
        assert!(matches!(judge(&run, &silent), Verdict::Refused(r) if r.contains("no reason")));
        assert!(parse_equivalents("no reason separator").is_err());
    }

    #[test]
    fn load_refuses_a_missing_list() {
        let err = Outcomes::load(Path::new("/nonexistent/m2")).unwrap_err();
        assert!(err.contains("caught.txt"));
    }
}
