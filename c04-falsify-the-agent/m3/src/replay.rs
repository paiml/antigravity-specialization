//! The agent's patch, replayed, judged by property tests.
//!
//! `clamp_to_width` and the `agent_tests` module below are copied verbatim from the
//! recorded run `fixtures/agy-runs/m3-clamp-width/patch.diff` (agy, gemini-4-neon-high,
//! 2026-11-20). CI replays the patch; it never calls agy. A test checks the copy
//! against the recorded diff line by line.

use crate::clamp;
use crate::props::{counterexample, runner};
use proptest::prelude::*;

/// The recorded patch, as the agent wrote it.
pub const PATCH: &str = include_str!("../../fixtures/agy-runs/m3-clamp-width/patch.diff");

// ---- begin verbatim agent code (patch.diff, src/lib.rs hunk 1) ----
/// Clamp `x` into `[center - width, center + width]`.
///
/// Follows contract `clamp_to_width-v1`; the caller owes `width >= 0`.
/// Uses saturating arithmetic on the bounds so extreme `center` / `width`
/// values near `i64::MIN` or `i64::MAX` preserve exact mathematical clamping
/// without overflowing.
pub fn clamp_to_width(x: i64, center: i64, width: i64) -> i64 {
    let lo = center.saturating_sub(width);
    let hi = center.saturating_add(width);
    clamp(x, lo, hi)
}
// ---- end verbatim agent code ----

/// Hand-written contrast, NOT from the agent: the same idea with wrapping bounds.
pub fn wrapping_clamp_to_width(x: i64, center: i64, width: i64) -> i64 {
    clamp(x, center.wrapping_sub(width), center.wrapping_add(width))
}

/// Oracle: clamp `x` into the exact range `[center - width, center + width]`, computed in `i128`.
pub fn oracle(x: i64, center: i64, width: i64) -> i64 {
    let (x, c, w) = (i128::from(x), i128::from(center), i128::from(width));
    let r = x.max(c - w).min(c + w);
    i64::try_from(r).expect("a clamp of an i64 into a range that meets i64 stays in i64")
}

/// Any `x` and `center`, and `width >= 0` (the contract's precondition).
pub fn width_case() -> impl Strategy<Value = (i64, i64, i64)> {
    (any::<i64>(), any::<i64>(), 0..=i64::MAX)
}

/// Runs `f` against the oracle on 256 seeded cases. `None` = all agreed; `Some` = shrunk counterexample.
pub fn disagreement(f: fn(i64, i64, i64) -> i64) -> Option<(i64, i64, i64)> {
    let result = runner(None).run(&width_case(), |(x, c, w)| {
        prop_assert_eq!(f(x, c, w), oracle(x, c, w));
        Ok(())
    });
    counterexample(result)
}

/// The agent's `fn` lines that must appear, added, in the recorded patch.
pub fn replayed_lines() -> [&'static str; 4] {
    [
        "pub fn clamp_to_width(x: i64, center: i64, width: i64) -> i64 {",
        "    let lo = center.saturating_sub(width);",
        "    let hi = center.saturating_add(width);",
        "    clamp(x, lo, hi)",
    ]
}

/// True when every line in `lines` appears as an added line (`+...`) of `patch`.
pub fn patch_adds(patch: &str, lines: &[&str]) -> bool {
    lines
        .iter()
        .all(|want| patch.lines().any(|l| l.strip_prefix('+') == Some(want)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_copy_matches_the_recorded_patch() {
        assert!(patch_adds(PATCH, &replayed_lines()));
        assert!(!patch_adds(
            PATCH,
            &["    clamp(x, center - width, center + width)"]
        ));
    }

    #[test]
    fn the_agent_patch_agrees_with_the_oracle() {
        assert_eq!(disagreement(clamp_to_width), None);
    }

    #[test]
    fn the_wrapping_contrast_is_caught() {
        let (x, c, w) = disagreement(wrapping_clamp_to_width).expect("wrapping bounds disagree");
        assert_ne!(wrapping_clamp_to_width(x, c, w), oracle(x, c, w));
    }
}

// ---- begin verbatim agent tests (patch.diff, src/lib.rs hunk 2) ----
#[cfg(test)]
mod clamp_to_width_tests {
    use super::{clamp, clamp_to_width};

    #[test]
    fn clamp_to_width_stays_in_range() {
        assert_eq!(clamp_to_width(20, 10, 3), 13);
        assert_eq!(clamp_to_width(0, 10, 3), 7);
        assert_eq!(clamp_to_width(11, 10, 3), 11);
        assert_eq!(clamp_to_width(7, 10, 3), 7);
        assert_eq!(clamp_to_width(13, 10, 3), 13);
        assert_eq!(clamp_to_width(-20, -10, 3), -13);
        assert_eq!(clamp_to_width(0, -10, 3), -7);
        assert_eq!(clamp_to_width(-10, -10, 3), -10);
    }

    #[test]
    fn clamp_to_width_zero_width() {
        assert_eq!(clamp_to_width(100, 5, 0), 5);
        assert_eq!(clamp_to_width(-100, 5, 0), 5);
        assert_eq!(clamp_to_width(5, 5, 0), 5);
        assert_eq!(clamp_to_width(i64::MAX, i64::MIN, 0), i64::MIN);
        assert_eq!(clamp_to_width(i64::MIN, i64::MAX, 0), i64::MAX);
    }

    #[test]
    fn clamp_to_width_idempotent_and_matches_clamp() {
        for &center in &[-10, -1, 0, 1, 10] {
            for &width in &[0, 1, 3, 15] {
                for &x in &[-30, -10, -2, 0, 2, 10, 30] {
                    let y = clamp_to_width(x, center, width);
                    assert_eq!(y, clamp(x, center - width, center + width));
                    assert_eq!(clamp_to_width(y, center, width), y);
                    assert!(y >= center - width && y <= center + width);
                }
            }
        }
    }

    #[test]
    fn clamp_to_width_handles_i64_boundaries() {
        assert_eq!(clamp_to_width(i64::MAX, i64::MAX, 5), i64::MAX);
        assert_eq!(clamp_to_width(0, i64::MAX, 5), i64::MAX - 5);
        assert_eq!(clamp_to_width(i64::MIN, i64::MIN, 5), i64::MIN);
        assert_eq!(clamp_to_width(0, i64::MIN, 5), i64::MIN + 5);
        assert_eq!(clamp_to_width(0, 1, i64::MAX), 0);
        assert_eq!(clamp_to_width(0, -2, i64::MAX), 0);
        assert_eq!(clamp_to_width(5, i64::MIN, i64::MAX), -1);
        assert_eq!(clamp_to_width(-5, i64::MAX, i64::MAX), 0);
    }
}
// ---- end verbatim agent tests ----
