//! Two pass-rate gates over a test report.
//!
//! [`no_floor`] is the gate `m4_empty_gate` shows: it scores the pass rate and
//! nothing else, so an empty report scores 1.0 and passes.
//! [`with_floor`] is the fix `m4_falsifier` shows: fewer tests than the floor is red.

use crate::report::Report;

/// Pass rate of a report. An empty report has no failures, so it scores 1.0:
/// that is the vacuous green this module is about.
pub fn pass_rate(report: &Report) -> f64 {
    match report.total() {
        0 => 1.0,
        total => report.passed as f64 / total as f64,
    }
}

/// Passes when the pass rate reaches `min_rate`. It has no floor.
pub fn no_floor(report: &Report, min_rate: f64) -> bool {
    pass_rate(report) >= min_rate
}

/// Passes only when at least `floor` tests ran and the rate reaches `min_rate`.
pub fn with_floor(report: &Report, min_rate: f64, floor: usize) -> bool {
    report.total() >= floor && no_floor(report, min_rate)
}

#[cfg(test)]
mod tests {
    use super::*;

    const EMPTY: Report = Report {
        passed: 0,
        failed: 0,
    };
    const RED: Report = Report {
        passed: 2,
        failed: 1,
    };
    const GREEN: Report = Report {
        passed: 5,
        failed: 0,
    };

    #[test]
    fn empty_report_scores_one() {
        assert_eq!(pass_rate(&EMPTY), 1.0);
    }

    #[test]
    fn no_floor_passes_an_empty_report() {
        assert!(no_floor(&EMPTY, 1.0));
    }

    #[test]
    fn no_floor_refuses_a_failure() {
        assert!(!no_floor(&RED, 1.0));
        assert!(no_floor(&GREEN, 1.0));
    }

    #[test]
    fn floor_refuses_an_empty_report() {
        assert!(!with_floor(&EMPTY, 1.0, 1));
    }

    #[test]
    fn floor_refuses_too_few_tests() {
        assert!(!with_floor(&GREEN, 1.0, 6));
        assert!(with_floor(&GREEN, 1.0, 5));
    }

    #[test]
    fn floor_still_refuses_a_failure() {
        assert!(!with_floor(&RED, 1.0, 1));
    }
}
