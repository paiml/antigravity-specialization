# Setting up Dockerfile linting for pull requests

Configures a pull_request workflow filtered to Dockerfile changes and pairs it with a deterministic bash+awk Dockerfile linter enforcing pinned tags, WORKDIR over RUN cd, COPY over ADD, package cache cleanup, and non-root USER.

## Run

```bash
./lint-dockerfile.sh Dockerfile.good
```

Test against the failing fixture:

```bash
./lint-dockerfile.sh Dockerfile.bad
```

## Verify

```bash
./verify.sh
```

Requires bash and standard POSIX tools (awk, grep, mktemp). Runs offline without Docker or hadolint.

The workflow in `.github/workflows/dockerfile-lint.yml` shows how to trigger on `pull_request` only when `**/Dockerfile*` changes and run both `hadolint` in GitHub Actions and `./lint-dockerfile.sh` locally. Running `./verify.sh` proves the linter accepts `Dockerfile.good` and catches every planted violation in `Dockerfile.bad`.

| file | |
|---|---|
| `.github/workflows/dockerfile-lint.yml` | pull_request workflow triggered on Dockerfile paths |
| `lint-dockerfile.sh` | deterministic Dockerfile linter (supports --self-test) |
| `Dockerfile.good` | compliant Dockerfile with pinned tag, WORKDIR, COPY, and non-root USER |
| `Dockerfile.bad` | non-compliant Dockerfile violating 5 rules |
| `verify.sh` | proves Dockerfile.good passes and Dockerfile.bad plus empty/missing files fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m5-dockerfile-linting/example.toml` and re-render.</sub>
