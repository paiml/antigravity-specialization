//! The falsifier: one input that must make the gate red.
//!
//! Before a gate is trusted, hand it the empty artifact. A gate that passes
//! it cannot say no, and its green means nothing.

use crate::report::Report;

/// What the falsifier found.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Verdict {
    /// The gate passed the empty artifact. Do not trust its green.
    CannotSayNo,
    /// The gate refused the empty artifact. It can say no.
    RefusesEmpty,
}

/// Runs `gate` on the empty report and says whether it refused it.
pub fn falsify(gate: &dyn Fn(&Report) -> bool) -> Verdict {
    if gate(&Report::default()) {
        Verdict::CannotSayNo
    } else {
        Verdict::RefusesEmpty
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::gate;

    #[test]
    fn falsifier_catches_the_gate_with_no_floor() {
        assert_eq!(falsify(&|r| gate::no_floor(r, 1.0)), Verdict::CannotSayNo);
    }

    #[test]
    fn falsifier_clears_the_gate_with_a_floor() {
        assert_eq!(
            falsify(&|r| gate::with_floor(r, 1.0, 1)),
            Verdict::RefusesEmpty
        );
    }

    #[test]
    fn a_floor_of_zero_is_no_floor() {
        assert_eq!(
            falsify(&|r| gate::with_floor(r, 1.0, 0)),
            Verdict::CannotSayNo
        );
    }
}
