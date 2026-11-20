//! Module 6: Second-model review and the capstone.
//!
//! Every review, mutant list and agent patch this crate reads is a recorded file under
//! `m6/fixtures/`. Nothing here calls agy or any model; CI replays the records.

pub mod receipt;
pub mod review;
pub mod shop;
pub mod tally;

/// Number of demo bins in this module.
pub const BINS: usize = 4;

/// Module title.
pub fn title() -> &'static str {
    "Second-model review and the capstone"
}

/// The recorded files, embedded so every bin and test reads the same bytes.
pub mod fixtures {
    /// The capstone agy run: the code-writing prompt and the patch it produced.
    pub const CAPSTONE_PROMPT: &str = include_str!("../fixtures/agy-runs/m6-capstone/prompt.md");
    /// The patch the capstone agy run produced.
    pub const CAPSTONE_PATCH: &str = include_str!("../fixtures/agy-runs/m6-capstone/patch.diff");
    /// The capstone agent's own summary of what it did (its self-grade).
    pub const CAPSTONE_STDOUT: &str = include_str!("../fixtures/agy-runs/m6-capstone/stdout.txt");
    /// Second model family reviewing the unedited agent patch.
    pub const REVIEW_AGENT_PATCH: &str =
        include_str!("../fixtures/reviews/m6-review-agent-patch/stdout.txt");
    /// The review subject: the capstone patch with the assertions of two tests removed.
    pub const SUBJECT_PATCH: &str = include_str!("../fixtures/subject/vacuous.patch.diff");
    /// Real `cargo mutants` output on the review subject.
    pub const SUBJECT_MUTANTS: &str = include_str!("../fixtures/subject/mutants.txt");
    /// Review by the author model (agy, gemini-4-neon-high), patch only.
    pub const REVIEW_AUTHOR: &str =
        include_str!("../fixtures/agy-runs/m6-review-author/stdout.txt");
    /// Review by a second model family (Claude), patch only.
    pub const REVIEW_SECOND: &str = include_str!("../fixtures/reviews/m6-review-second/stdout.txt");
    /// Third review seat (agy, gemini-4-neon-low), patch only.
    pub const REVIEW_THIRD: &str = include_str!("../fixtures/agy-runs/m6-review-third/stdout.txt");
    /// Author model again, handed the mutant list as well.
    pub const REVIEW_WITH_MUTANTS: &str =
        include_str!("../fixtures/agy-runs/m6-review-mutants/stdout.txt");
    /// The capstone receipt for the review subject.
    pub const RECEIPT_SUBJECT: &str = include_str!("../fixtures/receipts/subject.receipt.txt");
    /// The capstone receipt for the unedited agent patch.
    pub const RECEIPT_AGENT: &str = include_str!("../fixtures/receipts/agent.receipt.txt");
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn module_is_named_and_sized() {
        assert_eq!(BINS, 4);
        assert!(title().contains("capstone"));
    }
}
