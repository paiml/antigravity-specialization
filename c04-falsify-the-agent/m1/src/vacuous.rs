//! Demo `m1_vacuous`: the test that cannot fail.
//!
//! A check is a function that takes an implementation and says pass or fail.
//! The vacuous check calls the implementation and asserts nothing, so it passes
//! for every body. The real check compares against known answers.

/// An implementation under test: a member discount in cents.
pub type Discount = fn(u32) -> u32;

/// The right body: 10% off orders of 50.00 or more, capped at 20.00.
pub fn discount_right(subtotal_cents: u32) -> u32 {
    if subtotal_cents < 5_000 {
        return 0;
    }
    (subtotal_cents / 10).min(2_000)
}

/// A wrong body, the kind a careless edit leaves behind: no cap, no threshold.
pub fn discount_wrong(subtotal_cents: u32) -> u32 {
    subtotal_cents / 10
}

/// A check with no assertion. It runs the code, so it covers every line it
/// reaches, and it can never fail.
pub fn vacuous_check(f: Discount) -> bool {
    let _ = f(4_999);
    let _ = f(5_000);
    let _ = f(50_000);
    true
}

/// A check that states what the answer must be.
pub fn real_check(f: Discount) -> bool {
    f(4_999) == 0 && f(5_000) == 500 && f(50_000) == 2_000
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn vacuous_check_passes_both_bodies() {
        assert!(vacuous_check(discount_right));
        assert!(vacuous_check(discount_wrong));
    }

    #[test]
    fn real_check_refuses_the_wrong_body() {
        assert!(real_check(discount_right));
        assert!(!real_check(discount_wrong));
    }

    #[test]
    fn right_body_known_answers() {
        assert_eq!(discount_right(0), 0);
        assert_eq!(discount_right(4_999), 0);
        assert_eq!(discount_right(5_000), 500);
        assert_eq!(discount_right(20_000), 2_000);
        assert_eq!(discount_right(50_000), 2_000);
    }
}
