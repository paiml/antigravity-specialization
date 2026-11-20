You are reviewing a pull request written by a coding agent. The patch is in PATCH.diff in the current directory. Read it.

The task the agent was given: add `pub fn apply_discount(price_cents: u64, percent: u8) -> u64` that returns the price after taking `percent` percent off, rounded down to whole cents, with a percent above 100 treated as 100, plus unit tests in the same file.

Decide: should this pull request be accepted or refused? Judge the code AND the tests. You cannot run cargo.

MUTANTS.txt in the current directory holds the real `cargo mutants` output for this patch (cargo-mutants 27.1.0). Read it too, and use it to judge the tests.


Reply with findings first, one per line, each starting with "FINDING:". Then end your reply with exactly one line:
VERDICT: ACCEPT
or
VERDICT: REFUSE
