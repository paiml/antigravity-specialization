//! The agent's patch, replayed, against the property tests.
//!
//! Provable contract: the replayed `clamp_to_width` from run `m3-clamp-width` matches the
//! recorded diff and agrees with an `i128` oracle on 256 seeded cases with `width >= 0`;
//! a hand-written wrapping version of the same idea is caught by the same property.

use m3::replay::{
    clamp_to_width, disagreement, oracle, patch_adds, replayed_lines, wrapping_clamp_to_width,
    PATCH,
};

fn main() {
    assert!(patch_adds(PATCH, &replayed_lines()));
    println!("replayed: clamp_to_width from fixtures/agy-runs/m3-clamp-width/patch.diff");

    let agent = disagreement(clamp_to_width);
    println!("agent patch vs i128 oracle, 256 cases: {agent:?}");
    assert_eq!(agent, None);

    let (x, c, w) = disagreement(wrapping_clamp_to_width).expect("wrapping bounds disagree");
    let (got, want) = (wrapping_clamp_to_width(x, c, w), oracle(x, c, w));
    println!("hand-written wrapping contrast: (x, center, width) = ({x}, {c}, {w}) gives {got}, oracle {want}");
    assert_ne!(got, want);

    println!(
        "contract: m3-replay agent patch holds the property and the wrapping contrast is caught OK"
    );
}
