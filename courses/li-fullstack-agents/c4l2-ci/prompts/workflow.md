Write .github/workflows/ci.yml. It runs on pull requests and on pushes to main, in one job named gate with a timeout.
Steps: check out, set up Node from .nvmrc, run `make ci`, run `make smoke`. It must call the same make targets I run locally, so there is one definition of "green".
Do not use continue-on-error and do not add `|| true` to any command.
