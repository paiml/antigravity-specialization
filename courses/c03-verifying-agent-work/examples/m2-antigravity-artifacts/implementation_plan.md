# Implementation Plan

Add a deterministic checksum verification step to the pipeline before reporting success.

## User Review Required

- Confirm whether warnings should fail the gate immediately or be logged separately.

## Proposed Changes

- Update `check-artifacts.sh` to enforce non-empty plan, task, and walkthrough artifacts.
- Reject any walkthrough containing `TODO` or `TBD`.

## Verification Plan

- Run `./check-artifacts.sh .` and confirm exit status `0`.
- Run `./verify.sh` and confirm `contract: m2-antigravity-artifacts OK`.
