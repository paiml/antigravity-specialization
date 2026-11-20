//! FALSIFY-DISCOUNT-002: the discounted price never exceeds the price.
//! A seeded LCG drives 10 000 cases; no dependency is added.

use m6::shop::apply_discount;

fn lcg(state: &mut u64) -> u64 {
    *state = state
        .wrapping_mul(6_364_136_223_846_793_005)
        .wrapping_add(1_442_695_040_888_963_407);
    *state
}

#[test]
fn never_above_price() {
    let mut s = 0x5eed_u64;
    for _ in 0..10_000 {
        let price = lcg(&mut s);
        let percent = (lcg(&mut s) >> 56) as u8;
        let out = apply_discount(price, percent);
        assert!(out <= price, "apply_discount({price}, {percent}) = {out}");
        if percent >= 100 {
            assert_eq!(out, 0, "apply_discount({price}, {percent}) is not capped");
        }
    }
}
