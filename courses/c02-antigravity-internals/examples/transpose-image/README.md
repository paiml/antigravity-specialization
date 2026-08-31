# Transpose an image

Mirrors an image across the diagonal from its top-left corner, turning 502x460 into 460x502. Not a rotation: -rotate 90 gives the same dimensions and a different picture, differing in 97024 pixels.

## Run

```bash
./transpose.sh nostar.png out.png
```

Requires ImageMagick 6 (`convert`) or 7 (`magick`). The script picks whichever is installed.

Transposing twice returns the original exactly, which is the cheapest way to prove the operation was the one you meant.

| file | |
|---|---|
| `transpose.sh` | the script |
| `nostar.png` | input, 502x460, the course 1 output |
| `transposed.png` | expected output, 460x502 |

---

<sub>Generated — do not edit by hand. Edit `courses/c02-antigravity-internals/examples/transpose-image/example.toml` and re-render.</sub>
