You are working in a small Rust library crate (the current directory).

Add one public function to src/lib.rs:

    pub fn shipping_cents(weight_grams: u32, express: bool) -> u32

Rules:
- A parcel of 0 grams is an error in the caller; return 0 for it.
- Up to and including 1000 grams costs 500 cents.
- Above 1000 grams, add 200 cents for every started 500 grams over 1000.
- Express doubles the total.

Add unit tests for it in the same file. Do not add dependencies.
You cannot run cargo on this machine, so do not try.
When you are done, reply with a short summary of what you changed.
