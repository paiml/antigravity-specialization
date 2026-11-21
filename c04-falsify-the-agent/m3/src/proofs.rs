//! Kani harness for contract `clamp-v1`. Compiled only under `cargo kani`.

use crate::clamp;

/// For every `i64` triple with `lo <= hi`, the result is inside `[lo, hi]`.
#[kani::proof]
fn clamp_in_range_for_all_ordered_bounds() {
    let x: i64 = kani::any();
    let lo: i64 = kani::any();
    let hi: i64 = kani::any();
    kani::assume(lo <= hi);
    let r = clamp(x, lo, hi);
    assert!(lo <= r && r <= hi);
}
