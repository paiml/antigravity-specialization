# Measured on a build host

Tool output for the recorded run, produced by `m1/scripts/measure-on-build-host.sh` on a build host
(first line of `host.txt` names host, time and tool versions). `before` is `crate/` as
given to the agent; `after` is `crate/` with `../patch.diff` applied. Verbatim tail of
each command, then `exit=<code>`. Never edited by hand.

`caught.txt` is `mutants.out/caught.txt` from the second run on the `after` crate.
