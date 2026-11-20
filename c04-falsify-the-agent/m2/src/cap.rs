//! The `m2_equivalent` demo: a check that can never fail, and the mutant no test can kill.
//!
//! `cap_is_valid` runs after the cap, so it is `true` for every `u8`. The
//! mutant that replaces it with `true` changes nothing: it is equivalent.
//! It is listed with its reason in `mutants/cap/equivalents.txt`, never hidden.

/// Caps a percentage at 100.
pub fn cap_percent(p: u8) -> u8 {
    p.min(100)
}

/// The guard after the cap. Dead logic: no input makes it `false`.
pub fn cap_is_valid(p: u8) -> bool {
    cap_percent(p) <= 100
}

#[cfg(test)]
mod tests {
    use super::{cap_is_valid, cap_percent};

    #[test]
    fn caps_at_one_hundred() {
        assert_eq!(cap_percent(0), 0);
        assert_eq!(cap_percent(50), 50);
        assert_eq!(cap_percent(100), 100);
        assert_eq!(cap_percent(250), 100);
    }

    #[test]
    fn the_guard_holds_for_every_input() {
        assert!((0..=u8::MAX).all(cap_is_valid));
    }
}
