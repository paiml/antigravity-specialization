# Interview before you plan

Rung zero. The interview asks one question at a time, each with a recommended answer, and reads the repository instead of asking whenever the repository can answer. implementation_plan.md is a real artifact from one of these sessions, kept with its open questions still in it.

## Run

```bash
./grill.sh
```

Requires the Antigravity CLI (`agy`). The interview is interactive, so this example does not run headless.

The check that can fail: ask about something this repository already states, such as an image's dimensions or the colour `remove_star.sh` fills with, and it should go read rather than ask you. Ask about something the repository does not state, such as whether transpose means `-transpose` or `-rotate 90`, and it should ask, with a recommendation attached.

`implementation_plan.md` still carries its `User Review Required` section: three decisions the interview surfaced and deliberately did not settle. It also proposes Rust and the `magick` binary, neither of which this repository uses, which is the argument for reading a plan before running it.

| file | |
|---|---|
| `grill.sh` | starts the interview |
| `implementation_plan.md` | a real plan an interview produced |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/grill-me-first/example.toml` and re-render.</sub>
