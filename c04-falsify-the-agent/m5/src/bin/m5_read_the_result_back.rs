//! m5_read_the_result_back: read the result back.
//!
//! Provable contract: a Save that only rewrites the status line to "Saved"
//! passes a check that reads the label and fails the check that reads the
//! saved count back; the wired Save passes both.

use m5::driver::{drive, recorder_script, Expect, Step};
use m5::page::{Handler, Page};

fn label_script() -> Vec<Step> {
    recorder_script()
        .into_iter()
        .map(|s| match s.control {
            "save" => Step {
                control: "save",
                expect: Expect::Status("Saved"),
            },
            _ => s,
        })
        .collect()
}

fn main() {
    let fake = || Page::recorder().with_handler("save", Handler::StatusOnly("Saved"));

    let by_label = drive(&mut fake(), &label_script());
    println!("label check on the fake Save: {by_label:?}");
    let by_state = drive(&mut fake(), &recorder_script());
    println!("read-back check on the fake Save: {by_state:?}");
    let wired_label = drive(&mut Page::recorder(), &label_script());
    let wired_state = drive(&mut Page::recorder(), &recorder_script());
    println!("wired Save: label {wired_label:?}, read-back {wired_state:?}");

    assert_eq!(by_label, Ok(3));
    assert_eq!(by_state.map_err(|f| f.control), Err("save"));
    assert_eq!((wired_label, wired_state), (Ok(3), Ok(3)));
    println!("contract: a label-only Save passes the label check and fails the read-back OK");
}
