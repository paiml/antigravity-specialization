//! Module 1: The vacuous green.
//!
//! Four lesson demos share this library:
//! - [`vacuous`]: a test with no assertion passes on a wrong body (lesson 1.2).
//! - [`asserts`]: count the assertions in each `#[test]` fn (lesson 1.3).
//! - [`measured`]: read the coverage and mutant numbers recorded for an agent run (lesson 1.1).
//! - [`floor`]: a test-name floor that refuses a deleted or ignored test (lesson 1.4).

pub mod asserts;
pub mod floor;
pub mod measured;
pub mod vacuous;
