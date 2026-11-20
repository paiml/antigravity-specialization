//! m1: demos of a green suite that checks nothing.
//!
//! Four demo bins share this library:
//! - [`vacuous`]: a test with no assertion passes on a wrong body (`m1_vacuous`).
//! - [`asserts`]: count the assertions in each `#[test]` fn (`m1_covered_not_checked`).
//! - [`measured`]: read the coverage and mutant numbers recorded for an agent run (`m1_cold_open`).
//! - [`floor`]: a test-name floor that refuses a deleted or ignored test (`m1_test_floor`).

pub mod asserts;
pub mod floor;
pub mod measured;
pub mod vacuous;
