//! m6_tally: three saved reviews, one decision.
//!
//! Provable contract: the three recorded seats tally to a refusal, and a seat with no
//! readable verdict never counts as a yes (one accept beside two silent seats refuses).

use m6::fixtures::{REVIEW_AGENT_PATCH, REVIEW_AUTHOR, REVIEW_SECOND, REVIEW_THIRD};
use m6::review::Verdict;
use m6::tally::tally;

fn main() {
    let round = tally(&[REVIEW_AUTHOR, REVIEW_SECOND, REVIEW_THIRD]);
    println!("seats: agy gemini-4-neon-high, claude-sonnet-5-5, agy gemini-4-neon-low");
    println!("{}", round.receipt_line());
    let silent = tally(&[REVIEW_AGENT_PATCH, "seat timed out", ""]);
    println!(
        "one recorded ACCEPT beside two silent seats: {}",
        silent.receipt_line()
    );
    assert_eq!((round.accept, round.refuse, round.no_verdict), (0, 3, 0));
    assert_eq!(round.decision(), Verdict::Refuse);
    assert_eq!((silent.accept, silent.no_verdict), (1, 2));
    assert_eq!(silent.decision(), Verdict::Refuse);
    println!("contract: m6-tally three recorded seats refuse and a silent seat is not a yes OK");
}
