You are working in a small Rust library crate (the current directory).

Add one public function to src/lib.rs:

    pub fn apply_discount(price_cents: u64, percent: u8) -> u64

It returns the price after taking `percent` percent off, rounded down to whole cents.
A percent above 100 is treated as 100.

Add unit tests for it in the same file. Do not add dependencies.
You cannot run cargo on this machine, so do not try.
When you are done, reply with a short summary of what you changed.
