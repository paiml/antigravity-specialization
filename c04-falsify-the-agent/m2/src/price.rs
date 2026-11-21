//! The `m2_mutant` and `m2_kill` demos: a line total with a member discount.
//!
//! The default test only checks that the code runs. Every line is covered,
//! and most mutants survive. The `kill` feature adds the test that kills them.

/// Total in cents for `qty` units; members get 10% off a gross of 10_000 cents or more.
pub fn line_total(unit_cents: u32, qty: u32, member: bool) -> u32 {
    let gross = unit_cents * qty;
    if member && gross >= 10_000 {
        gross - gross / 10
    } else {
        gross
    }
}

#[cfg(test)]
mod tests {
    use super::line_total;

    /// The weak suite: it runs both branches and checks almost nothing.
    #[test]
    fn weak_suite_runs_the_code() {
        assert!(line_total(100, 2, false) > 0);
        assert!(line_total(5_000, 2, true) > 0);
    }

    /// The `m2_kill` test. Exact values, at and around the threshold.
    #[cfg(feature = "kill")]
    #[test]
    fn member_discount_at_the_threshold() {
        assert_eq!(line_total(100, 2, false), 200);
        assert_eq!(line_total(5_000, 2, false), 10_000);
        assert_eq!(line_total(5_000, 2, true), 9_000);
        assert_eq!(line_total(4_999, 2, true), 9_998);
        assert_eq!(line_total(6_000, 2, true), 10_800);
    }
}
