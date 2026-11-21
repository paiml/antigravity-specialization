You are working in a small Rust library crate (the current directory).
It has one function, `clamp` in src/lib.rs, and a contract for it in contracts/clamp-v1.yaml.

Add one public function to src/lib.rs:

    pub fn clamp_to_width(x: i64, center: i64, width: i64) -> i64

It clamps x into the range [center - width, center + width].

Add unit tests for it in src/lib.rs. Then write a contract for it,
contracts/clamp_to_width-v1.yaml, in the same format as contracts/clamp-v1.yaml,
and add a binding for it to contracts/binding.yaml. Do not add dependencies.
You cannot run cargo on this machine, so do not try.
When you are done, reply with a short summary of what you changed.
