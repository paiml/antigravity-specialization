# Release checklist

Run from a clean clone, not your working copy.

- [ ] `make ci` is green.
- [ ] `make smoke` prints `smoke OK`.
- [ ] `NODE_ENV=production node main.js` without `TASKPAD_TOKEN` exits 1 and says why.
- [ ] No token, password or key in the tree (`grep -rn "Bearer " .` shows only docs and tests).
- [ ] `docs/API.md` lists every route in `server.js`.
- [ ] The image builds, answers `/healthz`, and keeps its data across `docker restart`.
- [ ] The deploy script has been run once against a scratch directory, including a failing release that rolled back.
- [ ] `DECISIONS.md` has an entry for each choice made since the last release.
- [ ] Tag: `git tag v1.0.0`.

## Risk review

| Risk | Mitigation | Left over |
|---|---|---|
| One shared token | Constant-time compare, set per environment | Anyone with it can edit every task |
| `node:sqlite` is experimental | Pinned Node 22, thin data layer | An API change in a later Node needs a code change |
| Single database file | Volume plus backup | No high availability |
