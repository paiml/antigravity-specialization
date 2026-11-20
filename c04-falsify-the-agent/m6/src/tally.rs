//! Three saved reviews, one decision (`m6_tally`).
//!
//! A seat that produced no readable verdict is not a yes. The pull request is
//! accepted only when a strict majority of ALL seats accept; anything else refuses.

use crate::review::{parse_review, Verdict};

/// The count of one quorum round.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Tally {
    /// Seats that accepted.
    pub accept: usize,
    /// Seats that refused.
    pub refuse: usize,
    /// Seats with no readable verdict.
    pub no_verdict: usize,
}

impl Tally {
    /// Total seats counted.
    pub fn seats(&self) -> usize {
        self.accept + self.refuse + self.no_verdict
    }

    /// Accept only on a strict majority of all seats. Zero seats refuses.
    pub fn decision(&self) -> Verdict {
        if self.accept * 2 > self.seats() {
            Verdict::Accept
        } else {
            Verdict::Refuse
        }
    }

    /// The one receipt line for this round.
    pub fn receipt_line(&self) -> String {
        format!(
            "quorum: seats={} accept={} refuse={} no_verdict={} decision={}",
            self.seats(),
            self.accept,
            self.refuse,
            self.no_verdict,
            self.decision().word()
        )
    }
}

/// Count saved review texts. An unreadable review counts as `no_verdict`.
pub fn tally(reviews: &[&str]) -> Tally {
    let mut t = Tally::default();
    for text in reviews {
        match parse_review(text) {
            Ok(r) if r.verdict == Verdict::Accept => t.accept += 1,
            Ok(_) => t.refuse += 1,
            Err(_) => t.no_verdict += 1,
        }
    }
    t
}

#[cfg(test)]
mod tests {
    use super::*;

    const A: &str = "VERDICT: ACCEPT";
    const R: &str = "VERDICT: REFUSE";
    const X: &str = "the seat timed out";

    #[test]
    fn two_of_three_refusing_refuses() {
        let t = tally(&[A, R, R]);
        assert_eq!((t.accept, t.refuse, t.no_verdict), (1, 2, 0));
        assert_eq!(t.decision(), Verdict::Refuse);
        assert_eq!(
            t.receipt_line(),
            "quorum: seats=3 accept=1 refuse=2 no_verdict=0 decision=REFUSE"
        );
    }

    #[test]
    fn a_silent_seat_is_not_a_yes() {
        assert_eq!(tally(&[A, A, R]).decision(), Verdict::Accept);
        assert_eq!(tally(&[A, X, X]).decision(), Verdict::Refuse);
        assert_eq!(tally(&[A, A, X, X]).decision(), Verdict::Refuse);
        assert_eq!(tally(&[]).decision(), Verdict::Refuse);
    }
}
