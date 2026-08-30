# Complex image processing

Removes the star and its shadow from an image, filling both with the background colour.

## Run

```bash
./remove_star.sh pyramid-star.png out.png
```

Requires ImageMagick 6 (`convert`). On ImageMagick 7, use `magick`.

| file | |
|---|---|
| `remove_star.sh` | the script |
| `pyramid-star.png` | input, 502×460 |
| `pyramid_no_star.png` | expected output |
| `star-square-1920x1080.png` | a second still |

---

<sub>Generated — do not edit by hand. Edit `courses/c01-the-antigravity-platform/examples/complex-image-processing/example.toml` and re-render.</sub>
