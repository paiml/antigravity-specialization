//! `m2_diff_scope` demo: mutation scoped to a diff.
//!
//! Provable contract: the survivor inside the diff is reported, survivors outside it are dropped, and the reader agrees with cargo mutants --in-diff.
//! Every number printed comes from the saved `cargo mutants` run under `m2/mutants/`.

fn main() {
    let report = m2::demos::diff_scope(&m2::mutants_dir(), include_str!("../bulk.rs"))
        .expect("saved mutation run is readable");
    print!("{}", report.text);
    assert!(
        report.ok,
        "m2_diff_scope claim did not hold on the saved run"
    );
    println!("contract: m2-diff-scope reports the new survivor in the diff OK");
}
