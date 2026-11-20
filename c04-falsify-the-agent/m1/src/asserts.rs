//! Demo `m1_covered_not_checked`: 100% is a claim, not a fact.
//!
//! Line coverage says a line ran. It does not say a test checked the result.
//! This module finds every `#[test]` fn in a piece of Rust source and counts the
//! assertion macros in its body. A suite is refused when any test has none.
//!
//! The count is textual: `assert!`, `assert_eq!`, `assert_ne!`, `debug_assert*`
//! and `panic!` are counted, and a `#[should_panic]` test counts as checked.
//! An `.unwrap()` or a helper that asserts is NOT counted; the bin says so.

/// One test fn and the number of assertion macros in its body.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TestAsserts {
    pub name: String,
    pub asserts: usize,
}

const MACROS: [&str; 4] = ["assert!(", "assert_eq!(", "assert_ne!(", "panic!("];

/// Count the assertion macros in `body`. `debug_assert_eq!(` is counted once,
/// through its `assert_eq!(` suffix.
pub fn count_macros(body: &str) -> usize {
    MACROS.iter().map(|m| body.matches(m).count()).sum()
}

/// The text from the first `{` at or after `start` to its matching `}`.
/// Braces inside string literals are not special-cased; test bodies with an
/// unbalanced brace in a string are out of scope and give `None`.
pub fn brace_body(src: &str, start: usize) -> Option<&str> {
    let open = start + src[start..].find('{')?;
    let mut depth = 0usize;
    for (i, c) in src[open..].char_indices() {
        match c {
            '{' => depth += 1,
            '}' => {
                depth -= 1;
                if depth == 0 {
                    return Some(&src[open..=open + i]);
                }
            }
            _ => {}
        }
    }
    None
}

/// Every `#[test]` fn in `src` with its assertion count, in source order.
pub fn test_asserts(src: &str) -> Vec<TestAsserts> {
    let mut out = Vec::new();
    let mut from = 0;
    while let Some(at) = src[from..].find("#[test]") {
        let attr = from + at;
        from = attr + "#[test]".len();
        let Some(fn_at) = src[from..].find("fn ") else {
            break;
        };
        let head = &src[from..from + fn_at];
        let name_start = from + fn_at + 3;
        let name: String = src[name_start..]
            .chars()
            .take_while(|c| c.is_alphanumeric() || *c == '_')
            .collect();
        let Some(body) = brace_body(src, name_start) else {
            break;
        };
        let checked = head.contains("#[should_panic");
        let asserts = count_macros(body) + usize::from(checked);
        out.push(TestAsserts { name, asserts });
    }
    out
}

/// Tests with zero assertions.
pub fn unchecked(tests: &[TestAsserts]) -> Vec<&str> {
    tests
        .iter()
        .filter(|t| t.asserts == 0)
        .map(|t| t.name.as_str())
        .collect()
}

/// The suite is accepted only when it has at least one test and every test checks something.
pub fn suite_accepted(tests: &[TestAsserts]) -> bool {
    !tests.is_empty() && unchecked(tests).is_empty()
}

/// The lines a unified diff adds, without their leading `+`; `+++` headers are skipped.
pub fn added_lines(diff: &str) -> String {
    diff.lines()
        .filter(|l| l.starts_with('+') && !l.starts_with("+++"))
        .map(|l| &l[1..])
        .collect::<Vec<_>>()
        .join("\n")
}

#[cfg(test)]
mod tests {
    use super::*;

    const SRC: &str = r#"
#[cfg(test)]
mod tests {
    #[test]
    fn checks() { assert_eq!(1 + 1, 2); assert!(true); }

    #[test]
    fn runs_only() { let _ = 2 + 2; }

    #[test]
    #[should_panic]
    fn panics() { let v: Vec<u8> = vec![]; let _ = v[1]; }

    #[test]
    fn nested() { if true { debug_assert_ne!(1, 2); } }
}
"#;

    #[test]
    fn counts_each_test() {
        let t = test_asserts(SRC);
        let got: Vec<(&str, usize)> = t.iter().map(|x| (x.name.as_str(), x.asserts)).collect();
        assert_eq!(
            got,
            vec![
                ("checks", 2),
                ("runs_only", 0),
                ("panics", 1),
                ("nested", 1)
            ]
        );
    }

    #[test]
    fn refuses_a_suite_with_an_unchecked_test() {
        let t = test_asserts(SRC);
        assert_eq!(unchecked(&t), vec!["runs_only"]);
        assert!(!suite_accepted(&t));
    }

    #[test]
    fn refuses_an_empty_suite() {
        assert!(!suite_accepted(&[]));
    }

    #[test]
    fn accepts_a_checked_suite() {
        let t = test_asserts("#[test]\nfn a() { assert!(true); }");
        assert!(suite_accepted(&t));
    }

    #[test]
    fn unbalanced_or_truncated_source_stops_cleanly() {
        assert_eq!(brace_body("fn a() { {", 0), None);
        assert_eq!(brace_body("fn a()", 0), None);
        assert!(test_asserts("#[test]\nfn a() { {").is_empty());
        assert!(test_asserts("#[test]\nstruct S;").is_empty());
    }

    #[test]
    fn added_lines_skips_headers_and_context() {
        let diff = "--- a/x\n+++ b/x\n@@ -1 +1,2 @@\n ctx\n+new one\n-old\n+new two";
        assert_eq!(added_lines(diff), "new one\nnew two");
    }
}
