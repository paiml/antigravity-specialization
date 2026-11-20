//! Parse short durations such as "1h30m" into seconds.

/// Parse a duration made of `<number><unit>` parts, units `h`, `m` and `s`.
/// Returns `None` for an empty string or any malformed part.
pub fn parse_duration_secs(input: &str) -> Option<u64> {
    if input.is_empty() {
        return None;
    }
    let mut total = 0u64;
    let mut digits = String::new();
    for c in input.chars() {
        if c.is_ascii_digit() {
            digits.push(c);
            continue;
        }
        let n: u64 = digits.parse().ok()?;
        digits.clear();
        let unit = match c {
            'h' => 3_600,
            'm' => 60,
            _ => return None,
        };
        total += n * unit;
    }
    if !digits.is_empty() {
        return None;
    }
    Some(total)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_hours() {
        assert_eq!(parse_duration_secs("2h"), Some(7_200));
    }

    #[test]
    fn parses_minutes() {
        assert_eq!(parse_duration_secs("45m"), Some(2_700));
    }

    #[test]
    fn parses_mixed() {
        assert_eq!(parse_duration_secs("1h30m"), Some(5_400));
    }

    #[test]
    fn parses_seconds() {
        assert_eq!(parse_duration_secs("1m30s"), Some(90));
    }

    #[test]
    fn rejects_empty_and_malformed() {
        assert_eq!(parse_duration_secs(""), None);
        assert_eq!(parse_duration_secs("h"), None);
        assert_eq!(parse_duration_secs("10"), None);
    }
}
