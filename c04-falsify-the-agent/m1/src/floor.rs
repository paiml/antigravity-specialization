//! Demo `m1_test_floor`: the deleted test.
//!
//! An agent told to make CI green can delete a failing test or mark it
//! `#[ignore]`. Both make `cargo test` pass. The floor compares the test names
//! before and after a change: a name that disappears, or that is now ignored,
//! is refused.
//!
//! Input is the text of `cargo test -- --list` (every test, ignored ones too)
//! and of `cargo test -- --list --ignored` (ignored ones only).

use std::collections::BTreeSet;

/// Test names in `cargo test -- --list` output: lines that end in `: test`.
pub fn listed(list_output: &str) -> BTreeSet<String> {
    list_output
        .lines()
        .filter_map(|l| l.strip_suffix(": test"))
        .map(str::to_string)
        .collect()
}

/// What the floor found.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct FloorReport {
    /// Names present before and gone after.
    pub deleted: Vec<String>,
    /// Names present before and ignored after.
    pub ignored: Vec<String>,
    /// Tests that still run after the change.
    pub running_after: usize,
}

impl FloorReport {
    /// Green only when no test was deleted or ignored and at least one still runs.
    pub fn green(&self) -> bool {
        self.deleted.is_empty() && self.ignored.is_empty() && self.running_after > 0
    }
}

/// Compare the before and after listings.
pub fn check(before_list: &str, after_list: &str, after_ignored: &str) -> FloorReport {
    let before = listed(before_list);
    let after = listed(after_list);
    let ign = listed(after_ignored);
    FloorReport {
        deleted: before.difference(&after).cloned().collect(),
        ignored: before.intersection(&ign).cloned().collect(),
        running_after: after.difference(&ign).count(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const BEFORE: &str = "tests::a: test\ntests::b: test\n\n2 tests, 0 benchmarks\n";

    #[test]
    fn listed_reads_only_test_lines() {
        let names: Vec<String> = listed(BEFORE).into_iter().collect();
        assert_eq!(names, vec!["tests::a", "tests::b"]);
    }

    #[test]
    fn same_list_is_green() {
        let r = check(BEFORE, BEFORE, "");
        assert!(r.green());
        assert_eq!(r.running_after, 2);
    }

    #[test]
    fn a_deleted_test_is_red() {
        let r = check(BEFORE, "tests::a: test\n", "");
        assert_eq!(r.deleted, vec!["tests::b"]);
        assert!(!r.green());
    }

    #[test]
    fn an_ignored_test_is_red() {
        let r = check(BEFORE, BEFORE, "tests::b: test\n");
        assert_eq!(r.ignored, vec!["tests::b"]);
        assert_eq!(r.running_after, 1);
        assert!(!r.green());
    }

    #[test]
    fn no_running_test_is_red() {
        assert!(!check("", "", "").green());
    }

    #[test]
    fn an_added_test_is_green() {
        let after = "tests::a: test\ntests::b: test\ntests::c: test\n";
        assert!(check(BEFORE, after, "").green());
    }
}
