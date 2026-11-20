//! m3: contracts and properties on agent output.
//!
//! One function, [`clamp`], and the checks that judge what an agent writes about it:
//! a pv contract, the tests that contract names, property tests and a replayed patch.

pub mod lint_gate;
pub mod props;
pub mod pv;
pub mod replay;
pub mod symbolic;

#[cfg(kani)]
mod proofs;

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
