//! A libtest report, as `cargo test` or a `--test` binary prints it, read into counts.

/// Counts of test lines in one report.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Report {
    /// Lines of the form `test <name> ... ok`.
    pub passed: usize,
    /// Lines of the form `test <name> ... FAILED`.
    pub failed: usize,
}

impl Report {
    /// Every test the report names, passed or failed.
    pub fn total(&self) -> usize {
        self.passed + self.failed
    }
}

/// Reads a report. Only per-test lines count; the summary line is ignored,
/// so a report cannot claim tests it does not list.
pub fn parse(text: &str) -> Report {
    let mut report = Report::default();
    for line in text.lines() {
        let line = line.trim_end();
        if !line.starts_with("test ") || line.starts_with("test result:") {
            continue;
        }
        if line.ends_with(" ... ok") {
            report.passed += 1;
        } else if line.ends_with(" ... FAILED") {
            report.failed += 1;
        }
    }
    report
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_text_is_an_empty_report() {
        assert_eq!(parse(""), Report::default());
        assert_eq!(parse("").total(), 0);
    }

    #[test]
    fn counts_ok_and_failed_lines() {
        let text = "running 3 tests\n\
                    test a ... ok\n\
                    test b ... FAILED\n\
                    test c ... ok\n\
                    \n\
                    test result: FAILED. 2 passed; 1 failed; 0 ignored\n";
        let r = parse(text);
        assert_eq!((r.passed, r.failed, r.total()), (2, 1, 3));
    }

    #[test]
    fn summary_line_alone_claims_nothing() {
        let r = parse("test result: ok. 9 passed; 0 failed\n");
        assert_eq!(r.total(), 0);
    }

    #[test]
    fn ignored_and_other_lines_do_not_count() {
        let r = parse("test x ... ignored\nnote: something\ntest y ... ok\r\n");
        assert_eq!((r.passed, r.failed), (1, 0));
    }
}
