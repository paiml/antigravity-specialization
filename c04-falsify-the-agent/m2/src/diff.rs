//! A small unified-diff reader: which new-side lines a diff adds, and
//! replaying a one-file diff onto its base text.

/// One hunk of a one-file unified diff.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Hunk {
    pub old_start: usize,
    pub new_start: usize,
    pub lines: Vec<String>,
}

fn parse_range(text: &str) -> Result<usize, String> {
    let start = text.split(',').next().unwrap_or(text);
    start
        .parse()
        .map_err(|_| format!("bad hunk range: {text:?}"))
}

fn parse_header(line: &str) -> Result<(usize, usize), String> {
    let mut parts = line.split_whitespace();
    let (_, old, new) = (parts.next(), parts.next(), parts.next());
    let old = old.and_then(|o| o.strip_prefix('-'));
    let new = new.and_then(|n| n.strip_prefix('+'));
    match (old, new) {
        (Some(o), Some(n)) => Ok((parse_range(o)?, parse_range(n)?)),
        _ => Err(format!("bad hunk header: {line:?}")),
    }
}

/// Splits a diff into files (by `+++ ` path, `b/` stripped) and their hunks.
pub fn parse(diff: &str) -> Result<Vec<(String, Vec<Hunk>)>, String> {
    let mut files: Vec<(String, Vec<Hunk>)> = Vec::new();
    for line in diff.lines() {
        if let Some(path) = line.strip_prefix("+++ ") {
            let path = path.strip_prefix("b/").unwrap_or(path);
            files.push((path.to_string(), Vec::new()));
        } else if line.starts_with("@@ ") {
            let (old_start, new_start) = parse_header(line)?;
            let file = files.last_mut().ok_or("hunk before any +++ line")?;
            file.1.push(Hunk {
                old_start,
                new_start,
                lines: Vec::new(),
            });
        } else if let Some(hunk) = files.last_mut().and_then(|f| f.1.last_mut()) {
            hunk.lines.push(line.to_string());
        }
    }
    Ok(files)
}

/// Every (file, new-side line number) that the diff adds.
pub fn added_lines(diff: &str) -> Result<Vec<(String, u32)>, String> {
    let mut out = Vec::new();
    for (file, hunks) in parse(diff)? {
        for hunk in hunks {
            let mut n = hunk.new_start as u32;
            for line in &hunk.lines {
                if line.starts_with('+') {
                    out.push((file.clone(), n));
                    n += 1;
                } else if line.starts_with(' ') {
                    n += 1;
                }
            }
        }
    }
    Ok(out)
}

/// Replays a one-file diff onto `base`. A context or removed line that does
/// not match the base is an error, so a replay cannot drift silently.
pub fn apply(base: &str, diff: &str) -> Result<String, String> {
    let files = parse(diff)?;
    let [(_, hunks)] = files.as_slice() else {
        return Err(format!(
            "expected one file in the diff, found {}",
            files.len()
        ));
    };
    let old: Vec<&str> = base.lines().collect();
    let mut out: Vec<String> = Vec::new();
    let mut at = 0usize;
    for hunk in hunks {
        let start = hunk.old_start.saturating_sub(1).max(at);
        out.extend(old[at..start.min(old.len())].iter().map(|s| s.to_string()));
        at = start;
        for line in &hunk.lines {
            let (tag, body) = line.split_at(line.len().min(1));
            match tag {
                "+" => out.push(body.to_string()),
                " " | "-" => {
                    if old.get(at) != Some(&body) {
                        return Err(format!("base line {} does not match: {body:?}", at + 1));
                    }
                    if tag == " " {
                        out.push(body.to_string());
                    }
                    at += 1;
                }
                _ => {}
            }
        }
    }
    out.extend(old[at.min(old.len())..].iter().map(|s| s.to_string()));
    Ok(out.into_iter().map(|l| l + "\n").collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    const D: &str = "diff --git a/f.rs b/f.rs\n--- a/f.rs\n+++ b/f.rs\n@@ -1,3 +1,4 @@\n a\n-b\n+B\n+C\n c\n\\ No newline at end of file\n";

    #[test]
    fn applies_a_hunk_and_reports_added_lines() {
        assert_eq!(apply("a\nb\nc\nd\n", D).unwrap(), "a\nB\nC\nc\nd\n");
        assert_eq!(
            added_lines(D).unwrap(),
            vec![("f.rs".to_string(), 2), ("f.rs".to_string(), 3)]
        );
    }

    #[test]
    fn applies_a_new_file_and_a_later_hunk() {
        let new_file = "--- /dev/null\n+++ b/n.rs\n@@ -0,0 +1,2 @@\n+x\n+y\n";
        assert_eq!(apply("", new_file).unwrap(), "x\ny\n");
        let later = "+++ b/f.rs\n@@ -3 +3 @@\n-c\n+Z\n";
        assert_eq!(apply("a\nb\nc\nd\n", later).unwrap(), "a\nb\nZ\nd\n");
    }

    #[test]
    fn refuses_drift_and_bad_input() {
        assert!(apply("a\nX\nc\n", D)
            .unwrap_err()
            .contains("does not match"));
        assert!(apply("a\n", "").unwrap_err().contains("found 0"));
        assert!(parse("@@ -1 +1 @@\n").unwrap_err().contains("before any"));
        assert!(parse("+++ b/f\n@@ -x +1 @@\n")
            .unwrap_err()
            .contains("range"));
        assert!(parse("+++ b/f\n@@ junk\n").unwrap_err().contains("header"));
        assert_eq!(parse("noise\n").unwrap(), vec![]);
    }
}
