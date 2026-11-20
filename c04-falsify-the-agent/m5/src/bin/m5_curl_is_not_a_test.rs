//! m5_curl_is_not_a_test: why a curl is not a test.
//!
//! Provable contract: a page whose Save button is drawn but not wired passes
//! a curl-style GET (status 200, every button id in the body) and is refused
//! by the step driver, which clicks Save and reads the state back.

use m5::curl::{curl_says_ok, round_trip};
use m5::driver::{drive, recorder_script};
use m5::page::{Handler, Page};

fn main() {
    let ids = ["record", "stop", "save"];
    let mut dead = Page::recorder().with_handler("save", Handler::Dead);

    let (status, body) = round_trip(&dead.html()).expect("loopback GET");
    let curl_ok = curl_says_ok(status, &body, &ids);
    println!("curl: HTTP {status}, ids {ids:?} present: {curl_ok}");

    let verdict = drive(&mut dead, &recorder_script());
    println!("driver: {verdict:?}");

    let mut wired = Page::recorder();
    let fixed = drive(&mut wired, &recorder_script());
    println!("driver on the wired page: {fixed:?}");

    assert!(curl_ok, "curl must pass the dead page");
    assert_eq!(verdict.map_err(|f| f.control), Err("save"));
    assert_eq!(fixed, Ok(3));
    println!("contract: curl passes a dead Save button and the driver refuses it OK");
}
