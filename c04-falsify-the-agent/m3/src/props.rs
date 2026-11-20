//! Property tests for [`clamp`](crate::clamp), run through proptest's `TestRunner` (bins `m3_props`, `m3_shrink`).
//!
//! The runner is seeded with a fixed ChaCha RNG, so every run generates the same cases
//! and shrinks to the same counterexample. A failing property is a value here, not a
//! red test, so the demo bins can show it and still end green.

use proptest::prelude::*;
use proptest::test_runner::{
    Config, FailurePersistence, FileFailurePersistence, RngAlgorithm, TestError, TestRng,
    TestRunner,
};
use std::path::Path;

/// One generated input: `(x, lo, hi)`.
pub type Case = (i64, i64, i64);

/// Cases per property run.
pub const CASES: u32 = 256;

/// The `IN_RANGE` postcondition of `clamp-v1`: the result lies in `[lo, hi]`.
pub fn in_range(case: Case) -> bool {
    let (x, lo, hi) = case;
    let r = crate::clamp(x, lo, hi);
    lo <= r && r <= hi
}

/// Any three `i64` values, ordered or not.
pub fn any_case() -> impl Strategy<Value = Case> {
    (any::<i64>(), any::<i64>(), any::<i64>())
}

/// Three `i64` values with `lo <= hi`, the precondition of `clamp-v1`.
pub fn ordered_case() -> impl Strategy<Value = Case> {
    any_case().prop_map(|(x, a, b)| (x, a.min(b), a.max(b)))
}

/// A deterministic runner; `persistence` names a regression file, or `None` for none.
pub fn runner(persistence: Option<&Path>) -> TestRunner {
    let failure_persistence = persistence.map(|p| {
        let leaked: &'static str = Box::leak(p.to_string_lossy().into_owned().into_boxed_str());
        Box::new(FileFailurePersistence::Direct(leaked)) as Box<dyn FailurePersistence>
    });
    let config = Config {
        cases: CASES,
        failure_persistence,
        ..Config::default()
    };
    TestRunner::new_with_rng(config, TestRng::deterministic_rng(RngAlgorithm::ChaCha))
}

/// Checks `IN_RANGE` over `strategy`. `None` means every case held; `Some` is the shrunk counterexample.
pub fn find_escape(
    strategy: impl Strategy<Value = Case>,
    persistence: Option<&Path>,
) -> Option<Case> {
    let result = runner(persistence).run(&strategy, |case| {
        prop_assert!(in_range(case), "clamp{case:?} left the range");
        Ok(())
    });
    counterexample(result)
}

/// `None` when the run held, `Some` with the shrunk case when it failed. An aborted run is a
/// broken demo, never a pass, so it panics.
pub fn counterexample<T>(result: Result<(), TestError<T>>) -> Option<T> {
    match result {
        Ok(()) => None,
        Err(TestError::Fail(_, case)) => Some(case),
        Err(TestError::Abort(why)) => panic!("property run aborted: {why}"),
    }
}

/// The counterexample this seed shrinks to with proptest 1.12.0 (measured, `Cargo.lock` pins it).
/// Only `x` and `hi` reach 0; `lo` stops large. Raising the shrink budget does not move it.
pub const SHRUNK: Case = (0, 70_697_745_951_424_350, 0);

/// True when `case` escapes with reversed bounds and `x` and `hi` shrunk to 0.
pub fn is_shrunk_escape(case: Case) -> bool {
    let (x, lo, hi) = case;
    !in_range(case) && lo > hi && x == 0 && hi == 0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[should_panic(expected = "property run aborted")]
    fn an_aborted_run_is_never_a_pass() {
        let _ = counterexample::<Case>(Err(TestError::Abort("too many rejects".into())));
    }

    #[test]
    fn ordered_bounds_never_escape() {
        assert_eq!(find_escape(ordered_case(), None), None);
    }

    #[test]
    fn unordered_bounds_escape_and_shrink_to_the_measured_case() {
        let case = find_escape(any_case(), None).expect("lo > hi escapes");
        assert!(case.1 > case.2, "{case:?}");
        assert!(is_shrunk_escape(case), "{case:?}");
        assert_eq!(case, SHRUNK);
    }

    #[test]
    fn shrunk_escape_rejects_in_range_and_unshrunk_cases() {
        assert!(!is_shrunk_escape((0, 0, 1)));
        assert!(is_shrunk_escape((0, 10, 0)));
        assert!(!is_shrunk_escape((5, 1, 0)));
        assert!(!is_shrunk_escape((-5, 1, -9)));
    }

    #[test]
    fn the_same_seed_gives_the_same_counterexample() {
        assert_eq!(find_escape(any_case(), None), find_escape(any_case(), None));
    }
}
