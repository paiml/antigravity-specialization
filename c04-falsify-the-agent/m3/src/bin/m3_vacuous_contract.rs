//! The agent wrote the contract too.
//!
//! Provable contract: a contract counts as checked only when `pv check-symbolic` finds at
//! least one invariant that holds and none unparsed or violated; the agent's
//! `clamp_to_width-v1.yaml` (0 holds, 2 unparsed, pv exit 0) is refused, a hand-written
//! contract pv can evaluate is accepted, and one with a false invariant is refused.

use m3::symbolic::{accept, read};
use std::path::Path;

fn main() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("fixtures");
    let cases = [
        (
            "agent/m3-clamp-width/contracts/clamp_to_width-v1.yaml",
            false,
        ),
        ("hand/symbolic/span-holds-v1.yaml", true),
        ("hand/symbolic/span-violated-v1.yaml", false),
    ];
    for (file, want) in cases {
        let run = m3::pv::run(&root, &["check-symbolic", "--json", file]).expect("pv runs");
        let c = read(&run.stdout).expect("check-symbolic JSON");
        let ok = accept(c);
        println!(
            "{file}: holds {} violated {} unparsed {} (pv exit {}) -> {}",
            c.holds,
            c.violated,
            c.unparsed,
            run.exit,
            if ok { "ACCEPT" } else { "REFUSE" }
        );
        assert_eq!(ok, want, "{file}");
    }
    println!(
        "contract: m3-vacuous-contract counts only invariants pv evaluated and found holding OK"
    );
}
