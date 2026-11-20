//! `m2_kill` demo: kill the survivor.
//!
//! Provable contract: after the kill test every survivor of the weak suite is caught and the suite is accepted.
//! Every number printed comes from the saved `cargo mutants` run under `m2/mutants/`.

fn main() {
    let report =
        m2::demos::kill_the_survivor(&m2::mutants_dir()).expect("saved mutation run is readable");
    print!("{}", report.text);
    assert!(report.ok, "m2_kill claim did not hold on the saved run");
    println!("contract: m2-kill catches every weak-suite survivor OK");
}
