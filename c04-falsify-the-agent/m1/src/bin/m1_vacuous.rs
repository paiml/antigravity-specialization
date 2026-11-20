//! Lesson 1.2: the test that cannot fail.
//!
//! Two checks run against two bodies of the same function. The vacuous check
//! has no assertion; the real check states the answers.
//!
//! Provable contract: the vacuous check passes the right body AND the wrong
//! body; the real check passes the right body and refuses the wrong one.

use m1::vacuous::{discount_right, discount_wrong, real_check, vacuous_check};

fn verdict(pass: bool) -> &'static str {
    if pass {
        "PASS"
    } else {
        "FAIL"
    }
}

fn main() {
    let rows = [
        ("vacuous check", "right body", vacuous_check(discount_right)),
        ("vacuous check", "wrong body", vacuous_check(discount_wrong)),
        ("real check", "right body", real_check(discount_right)),
        ("real check", "wrong body", real_check(discount_wrong)),
    ];
    for (check, body, pass) in rows {
        println!("{check:<14} on {body}: {}", verdict(pass));
    }
    println!(
        "wrong body at 50_000: {} (right: {})",
        discount_wrong(50_000),
        discount_right(50_000)
    );
    assert!(
        rows[0].2 && rows[1].2,
        "the vacuous check passes both bodies"
    );
    assert!(
        rows[2].2 && !rows[3].2,
        "the real check refuses the wrong body"
    );
    println!("contract: m1-vacuous a test with no assertion passes a wrong body OK");
}
