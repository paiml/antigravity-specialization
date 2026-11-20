# Hand-written fixtures (not agent runs)

`vacuous-suite/` is the `m1-cold-open` crate with a test module written by hand for
the `m1_covered_not_checked` demo: every line runs and nothing is checked. It is its own workspace root, so the
demo workspace never builds it. Its coverage and mutant numbers are in
`vacuous-suite/measured/`, produced by `m1/scripts/measure-on-build-host.sh` on a build host.
