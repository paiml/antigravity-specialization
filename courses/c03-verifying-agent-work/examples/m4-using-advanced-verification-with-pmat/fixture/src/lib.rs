pub fn add_checked(left: i32, right: i32) -> Option<i32> {
    left.checked_add(right)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_within_bounds() {
        assert_eq!(add_checked(2, 3), Some(5));
    }
}
