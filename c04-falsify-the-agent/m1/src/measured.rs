//! Demo `m1_cold_open`: read the numbers measured on a recorded agent run.
//!
//! Two tool outputs are recorded beside the agent run, both produced on a
//! build host (any build host), never typed by hand:
//! - `cargo llvm-cov --summary-only`: the `TOTAL` row gives line coverage.
//! - `cargo mutants`: the final summary line gives caught, missed, unviable
//!   and timeout counts.

/// Line coverage from the `TOTAL` row of `cargo llvm-cov --summary-only`.
///
/// The row is `TOTAL` followed by numeric columns: regions, missed regions,
/// cover %, functions, missed functions, executed %, lines, missed lines,
/// cover %, then branch columns. Returns `(lines, missed_lines)`.
pub fn llvm_cov_lines(summary: &str) -> Option<(u64, u64)> {
    let row = summary.lines().find(|l| l.starts_with("TOTAL"))?;
    let cols: Vec<&str> = row.split_whitespace().collect();
    let lines = cols.get(7)?.parse().ok()?;
    let missed = cols.get(8)?.parse().ok()?;
    Some((lines, missed))
}

/// Line coverage in whole percent, rounded down.
pub fn percent(covered: u64, total: u64) -> u64 {
    covered * 100 / total.max(1)
}

/// Outcome counts from a `cargo mutants` run.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Mutants {
    pub caught: u64,
    pub missed: u64,
    pub unviable: u64,
    pub timeout: u64,
}

impl Mutants {
    /// Mutants that built and ran against the tests.
    pub fn viable(&self) -> u64 {
        self.caught + self.missed + self.timeout
    }
}

/// The number written just before `word` in `line`, e.g. `3 missed`.
fn count_before(line: &str, word: &str) -> u64 {
    let words: Vec<&str> = line
        .split(|c: char| c == ',' || c == ':' || c.is_whitespace())
        .filter(|w| !w.is_empty())
        .collect();
    words
        .windows(2)
        .find(|w| w[1] == word)
        .and_then(|w| w[0].parse().ok())
        .unwrap_or(0)
}

/// Parse the summary line `cargo mutants` prints last, of the form
/// `N mutants tested in T: A missed, B caught, C unviable`.
pub fn mutants_summary(output: &str) -> Option<Mutants> {
    let line = output
        .lines()
        .rev()
        .find(|l| l.contains("mutants tested"))?;
    Some(Mutants {
        caught: count_before(line, "caught"),
        missed: count_before(line, "missed"),
        unviable: count_before(line, "unviable"),
        timeout: count_before(line, "timeouts") + count_before(line, "timeout"),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    const COV: &str =
        "Filename  Regions Missed Cover Functions Missed Executed Lines Missed Cover\n\
---\n\
TOTAL 30 2 93.33% 3 0 100.00% 25 0 100.00% 0 0 -\n";

    #[test]
    fn reads_the_total_row() {
        assert_eq!(llvm_cov_lines(COV), Some((25, 0)));
    }

    #[test]
    fn no_total_row_is_none() {
        assert_eq!(llvm_cov_lines("Filename Lines\n"), None);
        assert_eq!(llvm_cov_lines("TOTAL 1 2"), None);
        assert_eq!(llvm_cov_lines("TOTAL 1 2 3 4 5 6 x 8"), None);
        assert_eq!(llvm_cov_lines("TOTAL 1 2 3 4 5 6 7 y"), None);
    }

    #[test]
    fn percent_rounds_down_and_survives_zero() {
        assert_eq!(percent(25, 25), 100);
        assert_eq!(percent(2, 3), 66);
        assert_eq!(percent(0, 0), 0);
    }

    #[test]
    fn reads_the_mutants_summary() {
        let out = "Found 12 mutants to test\nok       Unmutated baseline\n\
12 mutants tested in 9s: 7 missed, 4 caught, 1 unviable\n";
        let m = mutants_summary(out).expect("summary line");
        assert_eq!(
            m,
            Mutants {
                caught: 4,
                missed: 7,
                unviable: 1,
                timeout: 0
            }
        );
        assert_eq!(m.viable(), 11);
    }

    #[test]
    fn reads_timeouts() {
        let m = mutants_summary("5 mutants tested in 1m: 1 missed, 3 caught, 1 timeouts")
            .expect("summary line");
        assert_eq!(m.timeout, 1);
        assert_eq!(m.viable(), 5);
    }

    #[test]
    fn no_summary_is_none() {
        assert_eq!(mutants_summary("Found 3 mutants to test"), None);
    }
}
