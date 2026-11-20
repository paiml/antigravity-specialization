//! Shipping fees for a small shop.

/// Returns the shipping cost in cents for a parcel of the given weight.
///
/// - A weight of `0` grams returns `0`.
/// - Up to and including `1000` grams costs `500` cents.
/// - Above `1000` grams adds `200` cents per started `500` grams over `1000`.
/// - `express` doubles the total cost.
pub fn shipping_cents(weight_grams: u32, express: bool) -> u32 {
    if weight_grams == 0 {
        return 0;
    }

    let base = if weight_grams <= 1000 {
        500
    } else {
        let extra_blocks = (weight_grams - 1001) / 500 + 1;
        500 + extra_blocks * 200
    };

    if express {
        base * 2
    } else {
        base
    }
}

#[cfg(test)]
mod tests {
    use super::shipping_cents;

    #[test]
    fn zero_weight_returns_zero() {
        assert_eq!(shipping_cents(0, false), 0);
        assert_eq!(shipping_cents(0, true), 0);
    }

    #[test]
    fn base_tier_up_to_1000_grams() {
        assert_eq!(shipping_cents(1, false), 500);
        assert_eq!(shipping_cents(500, false), 500);
        assert_eq!(shipping_cents(1000, false), 500);
    }

    #[test]
    fn extra_weight_tiers_standard() {
        assert_eq!(shipping_cents(1001, false), 700);
        assert_eq!(shipping_cents(1500, false), 700);
        assert_eq!(shipping_cents(1501, false), 900);
        assert_eq!(shipping_cents(2000, false), 900);
        assert_eq!(shipping_cents(2001, false), 1100);
    }

    #[test]
    fn express_doubles_total() {
        assert_eq!(shipping_cents(1, true), 1000);
        assert_eq!(shipping_cents(1000, true), 1000);
        assert_eq!(shipping_cents(1001, true), 1400);
        assert_eq!(shipping_cents(1500, true), 1400);
        assert_eq!(shipping_cents(1501, true), 1800);
        assert_eq!(shipping_cents(2000, true), 1800);
        assert_eq!(shipping_cents(2001, true), 2200);
    }
}
