//! `m2_equivalent` demo: equivalent mutants and the honest score.
//!
//! Provable contract: every survivor is an equivalent named with a reason; the raw score is refused, the listed one accepted.
//! Every number printed comes from the saved `cargo mutants` run under `m2/mutants/`.

fn main() {
    let report =
        m2::demos::equivalent_mutants(&m2::mutants_dir()).expect("saved mutation run is readable");
    print!("{}", report.text);
    assert!(
        report.ok,
        "m2_equivalent claim did not hold on the saved run"
    );
    println!("contract: m2-equivalent lists every equivalent mutant with its reason OK");
}
