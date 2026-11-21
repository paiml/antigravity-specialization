# Create your first agent

An Antigravity agent is a markdown file with YAML frontmatter declaring its name, description, and execution policy, followed by persona instructions. verify-first.md instructs the agent to run checks before reporting success. verify.sh validates the agent definition offline without invoking agy.

## Run

```bash
./run-agent.sh
```

## Verify

```bash
./verify.sh
```

Live: needs agy. Requires the Antigravity CLI (`agy`) and global agent install (`~/.gemini/config/agents/`). `verify.sh` checks the agent spec offline without calling `agy`.

## Installing the agent

Agents load from `~/.gemini/config/agents/` or from an installed plugin. Copy the file globally and confirm it registered:

```bash
cp agents/verify-first.md ~/.gemini/config/agents/
agy agents
```

If the agent name does not appear in `agy agents`, the YAML frontmatter did not parse. Running `./validate-agent.sh agents/verify-first.md` catches missing delimiters, missing `name`/`description`, or an empty persona body before installation.

| file | |
|---|---|
| `agents/verify-first.md` | the agent definition: YAML frontmatter plus verification-first persona |
| `run-agent.sh` | live agy -p invocation using --mode plan |
| `validate-agent.sh` | validates agent frontmatter and persona body offline |
| `verify.sh` | proves valid agent passes and empty or malformed agents fail without running agy |

---

<sub>Generated — do not edit by hand. Edit `courses/c03-verifying-agent-work/examples/m2-create-first-agent/example.toml` and re-render.</sub>
