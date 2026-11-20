//! Order pricing for a small shop. No tests yet.

/// Shipping fee in cents for a parcel.
pub fn shipping_fee_cents(weight_grams: u32, express: bool) -> u32 {
    if weight_grams == 0 {
        return 0;
    }
    let mut fee = 499;
    if weight_grams > 1_000 {
        fee += (weight_grams - 1_000).div_ceil(500) * 150;
    }
    if express {
        fee *= 2;
    }
    fee
}

/// Member discount in cents: 10% off orders of 50.00 or more, capped at 20.00.
pub fn member_discount_cents(subtotal_cents: u32, member: bool) -> u32 {
    if !member || subtotal_cents < 5_000 {
        return 0;
    }
    (subtotal_cents / 10).min(2_000)
}

/// Order total in cents.
pub fn order_total_cents(
    subtotal_cents: u32,
    weight_grams: u32,
    express: bool,
    member: bool,
) -> u32 {
    subtotal_cents - member_discount_cents(subtotal_cents, member)
        + shipping_fee_cents(weight_grams, express)
}

// Hand-written for lesson 1.3, NOT an agent run: every line runs, nothing is checked.
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn shipping_fee_runs() {
        let _ = shipping_fee_cents(0, false);
        let _ = shipping_fee_cents(500, false);
        let _ = shipping_fee_cents(1_501, true);
    }

    #[test]
    fn member_discount_runs() {
        let _ = member_discount_cents(0, false);
        let _ = member_discount_cents(6_000, true);
    }

    #[test]
    fn order_total_runs() {
        let _ = order_total_cents(6_000, 1_501, true, true);
    }
}
