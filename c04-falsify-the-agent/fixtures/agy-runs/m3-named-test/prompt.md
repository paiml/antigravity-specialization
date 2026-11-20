You are working in a small Rust library crate (the current directory).
It has one function, `clamp` in src/lib.rs, and a contract for it in contracts/clamp-v1.yaml.

Extend contracts/clamp-v1.yaml. Add falsification tests so that each of these is covered:
1. a value below lo comes back as lo;
2. a value inside [lo, hi] comes back unchanged;
3. what happens when a caller passes lo > hi.
Each falsification test must name, in its `test:` field, the cargo test that checks it.

Edit only contracts/clamp-v1.yaml. Do not edit any Rust file.
You cannot run cargo on this machine, so do not try.
When you are done, reply with a short summary of what you changed.
