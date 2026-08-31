# Batch the pipeline

The plan from the interview, built. It replaces a bash loop with a concurrent runner: a thread pool, a progress bar, one aggregated log, and a batch that survives a bad file instead of stopping on it. It is an orchestrator, not an image processor; ImageMagick still does the pixels.

## Run

```bash
cargo run -- --dir images --cmd 'convert {} -transpose +repage {}.t.png'
```

Requires Rust (`cargo`) and ImageMagick. On ImageMagick 7 put `magick` in the command template instead of `convert`.

`cargo test` runs two unit tests over the template substitution.

## What `{}` expands to

`{}` is replaced by the file's **path as walked**, not its basename. For `--dir images` that is `images/pyramid-a.png`, so a template ending `out/{}` resolves to `out/images/pyramid-a.png` and fails unless that nested directory already exists:

    convert-im6.q16: unable to open image `out/images/pyramid-a.png': No such file or directory

That is measured, and it matters here: `out/{}` is the example the implementation plan itself proposes, and `Command Template Syntax` is one of the three decisions that plan listed under `User Review Required` and did not settle. The interview asked the right question, the plan answered it, and the answer does not survive contact with a subdirectory. Writing beside the input, as the command above does, works.

## Failure handling

A file that fails is logged and counted; the rest of the batch continues. The process exits `1` if anything failed and `0` if nothing did, so it composes with `&&`.

| file | |
|---|---|
| `Cargo.toml` | clap, rayon, indicatif, walkdir, shell-words |
| `Cargo.lock` | pinned dependency versions |
| `src/main.rs` | argument parsing, thread pool, progress bar, exit code |
| `src/worker.rs` | one task, plus the unit tests |
| `images/pyramid-a.png` | sample input, 502x460 |
| `images/pyramid-b.png` | a second one, so the batch has something to parallelise |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/batch-runner/example.toml` and re-render.</sub>
