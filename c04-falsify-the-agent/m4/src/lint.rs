//! Reads a recorded `pv lint` transcript and names what each flag did to a finding.
//!
//! A transcript is a sequence of blocks: a `$ <command>` line, pv's output
//! (with one `Summary: E errors, W warnings, S suppressed` line), and an
//! `[exit N]` line. The numbers come from real pv runs saved in `fixtures/`.

/// One `Summary:` line.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Summary {
    pub errors: usize,
    pub warnings: usize,
    pub suppressed: usize,
}

impl Summary {
    /// Findings the gate still shows.
    pub fn visible(&self) -> usize {
        self.errors + self.warnings
    }

    /// Findings the report accounts for, shown or suppressed.
    pub fn accounted(&self) -> usize {
        self.visible() + self.suppressed
    }
}

/// One recorded command and what it printed.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Run {
    pub command: String,
    pub summary: Option<Summary>,
    pub exit: Option<i32>,
}

/// What a flag does to a finding.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Lever {
    /// Raises a warning to an error (`--strict`).
    Promotes,
    /// Takes a finding out of the visible count (`--severity`, `--suppress-rule`).
    Hides,
}

/// Parses `Summary: 0 errors, 1 warnings, 0 suppressed`.
pub fn parse_summary(line: &str) -> Option<Summary> {
    let rest = line.trim().strip_prefix("Summary: ")?;
    let mut nums = rest.split(", ").map(|part| {
        let (n, _) = part.split_once(' ')?;
        n.parse::<usize>().ok()
    });
    let errors = nums.next()??;
    let warnings = nums.next()??;
    let suppressed = nums.next()??;
    Some(Summary {
        errors,
        warnings,
        suppressed,
    })
}

/// Parses a whole transcript into runs, in order.
pub fn parse_transcript(text: &str) -> Vec<Run> {
    let mut runs: Vec<Run> = Vec::new();
    for line in text.lines() {
        if let Some(cmd) = line.strip_prefix("$ ") {
            runs.push(Run {
                command: cmd.trim().to_string(),
                ..Run::default()
            });
        } else if let Some(run) = runs.last_mut() {
            if let Some(s) = parse_summary(line) {
                run.summary = Some(s);
            } else if let Some(code) = line
                .trim()
                .strip_prefix("[exit ")
                .and_then(|r| r.strip_suffix(']'))
            {
                run.exit = code.parse().ok();
            }
        }
    }
    runs
}

/// The levers a command line pulls, in the order they appear.
pub fn levers(command: &str) -> Vec<Lever> {
    command
        .split_whitespace()
        .filter_map(|tok| match tok.split('=').next() {
            Some("--strict") => Some(Lever::Promotes),
            Some("--severity") | Some("--suppress-rule") => Some(Lever::Hides),
            _ => None,
        })
        .collect()
}

/// Findings visible in `base` that `run` no longer shows. Over zero is a waiver.
pub fn hidden(base: &Summary, run: &Summary) -> usize {
    base.visible().saturating_sub(run.visible())
}

/// Findings that left the report entirely: not shown and not counted as suppressed.
pub fn vanished(base: &Summary, run: &Summary) -> usize {
    base.accounted().saturating_sub(run.accounted())
}

/// The report has errors, but the process exited 0: the exit code is not the gate.
pub fn exit_ignores_errors(run: &Run) -> bool {
    matches!((run.summary, run.exit), (Some(s), Some(0)) if s.errors > 0)
}

#[cfg(test)]
mod tests {
    use super::*;

    const T: &str = "$ pv lint contracts\n\
        [WARN] X\n\
        Summary: 0 errors, 1 warnings, 0 suppressed\n\
        Result: PASS\n\
        [exit 0]\n\
        $ pv lint contracts --severity error\n\
        Summary: 0 errors, 0 warnings, 0 suppressed\n\
        [exit 0]\n\
        $ pv lint contracts --strict\n\
        Summary: 1 errors, 0 warnings, 0 suppressed\n\
        [exit 0]\n\
        $ pv lint contracts --suppress-rule PV-VER-002 --strict\n\
        Summary: 0 errors, 0 warnings, 1 suppressed\n\
        [exit 1]\n";

    #[test]
    fn parses_a_summary_line() {
        let s = parse_summary("Summary: 2 errors, 3 warnings, 4 suppressed").unwrap();
        assert_eq!((s.errors, s.warnings, s.suppressed), (2, 3, 4));
        assert_eq!((s.visible(), s.accounted()), (5, 9));
    }

    #[test]
    fn refuses_a_malformed_summary() {
        assert_eq!(parse_summary("Result: PASS"), None);
        assert_eq!(
            parse_summary("Summary: x errors, 0 warnings, 0 suppressed"),
            None
        );
        assert_eq!(parse_summary("Summary: 0 errors, 0 warnings"), None);
        assert_eq!(parse_summary("Summary: 0errors"), None);
        assert_eq!(parse_summary("Summary: 0 errors"), None);
    }

    #[test]
    fn parses_a_transcript() {
        let runs = parse_transcript(T);
        assert_eq!(runs.len(), 4);
        assert_eq!(runs[1].command, "pv lint contracts --severity error");
        assert_eq!(runs[0].exit, Some(0));
        assert_eq!(runs[3].exit, Some(1));
        assert_eq!(runs[3].summary.unwrap().suppressed, 1);
    }

    #[test]
    fn output_before_any_command_is_ignored() {
        let runs = parse_transcript("Summary: 1 errors, 0 warnings, 0 suppressed\n[exit 0]\n");
        assert!(runs.is_empty());
    }

    #[test]
    fn a_bad_exit_line_is_not_a_number() {
        let runs = parse_transcript("$ pv lint\n[exit x]\n");
        assert_eq!(runs[0].exit, None);
    }

    #[test]
    fn names_the_levers() {
        assert_eq!(levers("pv lint contracts"), vec![]);
        assert_eq!(levers("pv lint --severity error"), vec![Lever::Hides]);
        assert_eq!(levers("pv lint --severity=error"), vec![Lever::Hides]);
        assert_eq!(
            levers("pv lint --suppress-rule PV-VER-002 --strict"),
            vec![Lever::Hides, Lever::Promotes]
        );
    }

    #[test]
    fn severity_hides_and_the_finding_vanishes() {
        let runs = parse_transcript(T);
        let base = runs[0].summary.unwrap();
        let sev = runs[1].summary.unwrap();
        assert_eq!(hidden(&base, &sev), 1);
        assert_eq!(vanished(&base, &sev), 1);
    }

    #[test]
    fn suppress_hides_but_keeps_count() {
        let runs = parse_transcript(T);
        let base = runs[0].summary.unwrap();
        let sup = runs[3].summary.unwrap();
        assert_eq!(hidden(&base, &sup), 1);
        assert_eq!(vanished(&base, &sup), 0);
    }

    #[test]
    fn strict_promotes_without_hiding() {
        let runs = parse_transcript(T);
        let base = runs[0].summary.unwrap();
        let strict = runs[2].summary.unwrap();
        assert_eq!(hidden(&base, &strict), 0);
        assert_eq!(strict.errors, 1);
    }

    #[test]
    fn spots_an_exit_that_ignores_errors() {
        let runs = parse_transcript(T);
        assert!(exit_ignores_errors(&runs[2]));
        assert!(!exit_ignores_errors(&runs[0]));
        assert!(!exit_ignores_errors(&Run::default()));
    }
}
