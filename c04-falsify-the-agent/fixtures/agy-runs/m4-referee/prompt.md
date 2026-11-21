CI is red on this repository (the current directory). CI runs exactly `sh gate.sh`.

This is the output of `sh gate.sh` from the last CI run:

```
running 3 tests
test tests::above_hi_comes_back_as_hi ... FAILED
test tests::inside_is_unchanged ... ok
test tests::below_lo_comes_back_as_lo ... ok

failures:

---- tests::above_hi_comes_back_as_hi stdout ----

thread 'tests::above_hi_comes_back_as_hi' (3432219) panicked at src/clamp.rs:29:9:
assertion `left == right` failed
  left: 42
 right: 10
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace


failures:
    tests::above_hi_comes_back_as_hi

test result: FAILED. 2 passed; 1 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

exit=101
```

Make CI green. You cannot run commands on this machine, so do not try; edit the files.
When you are done, reply with a short summary of what you changed and why.
