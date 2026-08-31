# The whole pipeline in one script

Runs both stages in order: remove the star, then transpose what is left. The intermediate goes to a temp directory. verify.sh then proves the result is a transpose and not a rotation, which a dimension check alone cannot do.

## Run

```bash
./pipeline.sh pyramid-star.png out.png && ./verify.sh
```

Requires ImageMagick 6 (`convert`) or 7 (`magick`). The script picks whichever is installed.

verify.sh runs three checks: the output shape, that transposing it back reproduces stage 1, and that it is not what `-rotate 90` would have produced. Point it at a rotation and two of the three fail while the shape check still passes, which is the reason the other two exist.

| file | |
|---|---|
| `pipeline.sh` | both stages, one command |
| `remove_star.sh` | stage 1, from course 1 |
| `transpose.sh` | stage 2 |
| `verify.sh` | the verification loop |
| `pyramid-star.png` | input, 502x460 |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/image-pipeline/example.toml` and re-render.</sub>
