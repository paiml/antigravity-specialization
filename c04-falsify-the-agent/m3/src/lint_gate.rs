//! Reads `pv lint --strict-test-binding --strict -f json` and gates on it (bin `m3_named_test_gate`).
//!
//! In text mode pv prints `[ERROR] PV-VER-002` for a cited test that is not in the
//! source, then `Result: PASS` and exit 0. The JSON carries `"passed": false` and the
//! `strict-test-binding` gate's `missing` count, so this module reads those instead.

use serde_json::Value;

/// What the `strict-test-binding` gate measured, plus the report's top-level verdict.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TestBinding {
    pub passed: bool,
    pub total_refs: u64,
    pub missing: u64,
}

/// Parses the top-level `passed` and the `strict-test-binding` gate's counts.
pub fn read(json: &str) -> Result<TestBinding, String> {
    let v: Value = serde_json::from_str(json).map_err(|e| format!("not JSON: {e}"))?;
    let passed = v["passed"].as_bool().ok_or("no top-level `passed`")?;
    let detail = v["gates"]
        .as_array()
        .and_then(|gates| gates.iter().find(|g| g["name"] == "strict-test-binding"))
        .map(|g| &g["detail"])
        .ok_or("no `strict-test-binding` gate in the report")?;
    let count = |key: &str| {
        detail[key]
            .as_u64()
            .ok_or_else(|| format!("no numeric `{key}` in strict-test-binding"))
    };
    Ok(TestBinding {
        passed,
        total_refs: count("total_refs")?,
        missing: count("missing")?,
    })
}

/// The cargo test names cited by `test:` lines of a contract, each once, in first-seen order.
/// Three falsification ids that cite one test give one name.
pub fn cited_tests(contract_yaml: &str) -> Vec<String> {
    let mut names: Vec<String> = Vec::new();
    for line in contract_yaml.lines() {
        let Some(rest) = line
            .trim_start()
            .trim_start_matches("- ")
            .strip_prefix("test:")
        else {
            continue;
        };
        let cmd = rest.trim().trim_matches('"');
        if let Some(name) = cmd.split_whitespace().last() {
            if !names.iter().any(|n| n == name) {
                names.push(name.to_string());
            }
        }
    }
    names
}

/// Accepted only when pv passed, at least one test is cited, and every cited test exists.
pub fn accept(b: TestBinding) -> bool {
    b.passed && b.total_refs > 0 && b.missing == 0
}

#[cfg(test)]
mod tests {
    use super::*;

    fn report(passed: bool, total: u64, missing: u64) -> String {
        format!(
            r#"{{"passed":{passed},"gates":[{{"name":"validate","detail":{{}}}},{{"name":"strict-test-binding","detail":{{"total_refs":{total},"existing":0,"missing":{missing}}}}}]}}"#
        )
    }

    #[test]
    fn a_dangling_test_is_refused() {
        let b = read(&report(false, 3, 1)).unwrap();
        assert_eq!(
            b,
            TestBinding {
                passed: false,
                total_refs: 3,
                missing: 1
            }
        );
        assert!(!accept(b));
    }

    #[test]
    fn zero_cited_tests_is_refused_not_passed() {
        assert!(!accept(read(&report(true, 0, 0)).unwrap()));
    }

    #[test]
    fn every_cited_test_present_is_accepted() {
        assert!(accept(read(&report(true, 3, 0)).unwrap()));
        assert!(!accept(read(&report(true, 3, 1)).unwrap()));
    }

    #[test]
    fn cited_tests_are_counted_once() {
        let yaml = "falsification_tests:\n  - test: \"cargo test --lib a\"\n  - test: \"cargo test --lib a\"\n    test:\n  - test: \"cargo test --lib b\"\n";
        assert_eq!(cited_tests(yaml), vec!["a".to_string(), "b".to_string()]);
        assert!(cited_tests("no tests here").is_empty());
    }

    #[test]
    fn malformed_reports_are_errors() {
        assert!(read("{").unwrap_err().contains("not JSON"));
        assert!(read(r#"{"gates":[]}"#).unwrap_err().contains("`passed`"));
        assert!(read(r#"{"passed":true,"gates":[]}"#)
            .unwrap_err()
            .contains("strict-test-binding"));
        let no_missing =
            r#"{"passed":true,"gates":[{"name":"strict-test-binding","detail":{"total_refs":1}}]}"#;
        assert!(read(no_missing).unwrap_err().contains("`missing`"));
    }
}
