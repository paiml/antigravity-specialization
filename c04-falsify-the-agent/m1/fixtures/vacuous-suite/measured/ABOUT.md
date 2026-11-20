# Measured on a build host

Produced by `m1/scripts/measure-on-build-host.sh` on a build host (`host.txt` names host, time
and tool versions).
Verbatim tail of each command, then `exit=<code>`. Never edited by hand.

- `llvm-cov-after.txt`: 40/40 lines, 100%.
- `mutants-after.txt`: 29 mutants, 27 missed, 2 caught. `caught.txt` lists the two. With
  no assertion, a mutant is caught only when the test panics. Both logs say
  `attempt to subtract with overflow` (debug build): a crash, not a checked value.
