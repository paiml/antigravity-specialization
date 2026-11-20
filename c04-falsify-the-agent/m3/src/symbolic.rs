//! Reads `pv check-symbolic --json` and judges it strictly (bin `m3_vacuous_contract`).
//!
//! pv prints `unparsed is NOT a pass` and still exits 0. This module refuses a contract
//! when any invariant is unparsed or violated, or when no invariant holds at all.

use serde_json::Value;

/// The three counts `pv check-symbolic --json` reports.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Counts {
    pub holds: u64,
    pub violated: u64,
    pub unparsed: u64,
}

/// Parses the counts out of `pv check-symbolic --json` output.
pub fn read(json: &str) -> Result<Counts, String> {
    let v: Value = serde_json::from_str(json).map_err(|e| format!("not JSON: {e}"))?;
    let count = |key: &str| {
        v[key]
            .as_u64()
            .ok_or_else(|| format!("no numeric `{key}` in check-symbolic output"))
    };
    Ok(Counts {
        holds: count("holds")?,
        violated: count("violated")?,
        unparsed: count("unparsed")?,
    })
}

/// A contract is evidence only when at least one invariant holds and none is unparsed or violated.
pub fn accept(c: Counts) -> bool {
    c.holds > 0 && c.violated == 0 && c.unparsed == 0
}

#[cfg(test)]
mod tests {
    use super::*;

    const SEED: &str = r#"{"holds":0,"violated":0,"unparsed":2,"invariants":[]}"#;

    #[test]
    fn the_seed_reads_as_zero_holds_two_unparsed() {
        let c = read(SEED).unwrap();
        assert_eq!((c.holds, c.violated, c.unparsed), (0, 0, 2));
        assert!(!accept(c));
    }

    #[test]
    fn only_all_holding_is_accepted() {
        let ok = Counts {
            holds: 2,
            violated: 0,
            unparsed: 0,
        };
        assert!(accept(ok));
        assert!(!accept(Counts { holds: 0, ..ok }));
        assert!(!accept(Counts { violated: 1, ..ok }));
        assert!(!accept(Counts { unparsed: 1, ..ok }));
    }

    #[test]
    fn junk_and_missing_counts_are_errors() {
        assert!(read("not json").unwrap_err().contains("not JSON"));
        let err = read(r#"{"holds":1,"violated":0}"#).unwrap_err();
        assert!(err.contains("`unparsed`"), "{err}");
    }
}
