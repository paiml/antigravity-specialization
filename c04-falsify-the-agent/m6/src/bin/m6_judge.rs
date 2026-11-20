//! m6_judge: the author cannot grade itself.
//!
//! Provable contract: the author's own summary carries no verdict and no finding, so it is
//! not a review; both recorded second reviews (a fresh agy session and a Claude session)
//! refuse the subject patch and name a vacuous test.

use m6::fixtures::{CAPSTONE_STDOUT, REVIEW_AUTHOR, REVIEW_SECOND};
use m6::review::{caught_vacuous, parse_review, ReviewError};

fn main() {
    let self_report = parse_review(CAPSTONE_STDOUT);
    let claim = CAPSTONE_STDOUT
        .lines()
        .find(|l| l.contains("was not run"))
        .expect("the summary says whether cargo ran");
    println!("author summary: {}", claim.trim_start_matches("- "));
    println!("author summary as a review: {self_report:?}");
    let seats = [
        ("agy gemini-4-neon-high (fresh session)", REVIEW_AUTHOR),
        ("claude-sonnet-5-5", REVIEW_SECOND),
    ];
    let mut caught = 0;
    for (who, text) in seats {
        let r = parse_review(text).expect("a recorded review has one verdict");
        let hit = caught_vacuous(&r);
        println!(
            "{who}: verdict={} findings={} caught_vacuous={hit}",
            r.verdict.word(),
            r.findings.len()
        );
        caught += usize::from(hit);
    }
    assert_eq!(self_report, Err(ReviewError::NoVerdict));
    assert_eq!(caught, seats.len());
    println!("contract: m6-judge a self-summary is no review and both second reviews caught the vacuous tests OK");
}
