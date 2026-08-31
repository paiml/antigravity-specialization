# A review agent that runs pmat

An agent is one markdown file: frontmatter naming it, then the persona. This one reviews by running pmat's quality gate and reporting what it measured. verify.sh plants a defect and proves the gate reports it, including the case where pmat finds something and still exits zero.

## Run

```bash
./verify.sh
```

Requires `pmat`. The agent itself needs the Antigravity CLI (`agy`) and is installed globally, not from this directory.

## Installing the agent

Agents load from `~/.gemini/config/agents/` or from an installed plugin. A workspace copy under `.agents/agents/` is silently ignored, so the file here is a sample to copy, not a live agent:

    cp agents/pmat-review.md ~/.gemini/config/agents/
    agy agents

`agy agents` lists what actually registered. If the name is missing, the file did not parse and nothing will say so.

## The number that misleads

pmat reports `Total violations` and `Blocking violations`, and the exit code tracks the blocking count only. A planted `TODO` produces `Total violations: 1`, `Blocking violations: 0`, `Quality Gate: PASSED`, exit `0`. An agent that trusts the exit code reports a clean review over a real finding, which is why the persona is told to read the totals and quote the scope line instead.

| file | |
|---|---|
| `agents/pmat-review.md` | the agent: frontmatter plus persona |
| `verify.sh` | proves the review can fail |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/pmat-review-agent/example.toml` and re-render.</sub>
