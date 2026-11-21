//! `m2_mutant` demo: what a mutant is.
//!
//! Provable contract: a suite that covers every line but leaves a mutant alive is refused.
//! Every number printed comes from the saved `cargo mutants` run under `m2/mutants/`.

fn main() {
    let report =
        m2::demos::what_a_mutant_is(&m2::mutants_dir()).expect("saved mutation run is readable");
    print!("{}", report.text);
    assert!(report.ok, "m2_mutant claim did not hold on the saved run");
    println!("contract: m2-mutant refuses a covering suite with survivors OK");
}
