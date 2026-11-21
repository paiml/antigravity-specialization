//! `m2_agent_suite` demo: mutation on agent output.
//!
//! Provable contract: the recorded agy patch replays byte for byte and its own suite is judged by the mutation run.
//! Every number printed comes from the saved `cargo mutants` run under `m2/mutants/`.

fn main() {
    let report = m2::demos::agent_suite(
        &m2::mutants_dir(),
        &m2::agy_run_dir(),
        include_str!("../agent_shipping.rs"),
    )
    .expect("saved mutation run is readable");
    print!("{}", report.text);
    assert!(
        report.ok,
        "m2_agent_suite claim did not hold on the saved run"
    );
    println!("contract: m2-agent-suite judges the replayed agent patch by its mutation run OK");
}
