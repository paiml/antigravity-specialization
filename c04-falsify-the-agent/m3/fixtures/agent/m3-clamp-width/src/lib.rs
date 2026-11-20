//! Clamp library.

/// Clamp `x` into `[lo, hi]`. Seed for contract `clamp-v1`; the caller owes `lo <= hi`.
pub fn clamp(x: i64, lo: i64, hi: i64) -> i64 {
    if x < lo {
        lo
    } else if x > hi {
        hi
    } else {
        x
    }
}

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

#[cfg(test)]
mod clamp_tests {
    use super::clamp;

    #[test]
    fn clamp_stays_in_range() {
        assert_eq!(clamp(9, 0, 5), 5);
        assert_eq!(clamp(-3, 0, 5), 0);
        assert_eq!(clamp(4, 0, 5), 4);
    }
}

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
