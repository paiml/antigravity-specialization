---
name: image-pipeline
description: Remove the star and its shadow from a pyramid still and transpose the result, in one step, using ImageMagick and bash. Use when asked to clean up, transpose, flip, reorient, or run the full pipeline on one of this project's pyramid images. Runs scripts/pipeline.sh; it does not reimplement the image processing in the prompt.
---

# Image pipeline

Cleans and reorients one of this project's pyramid stills in a single pass.

## When to use this

The user asks to remove the star, transpose the image, reorient it, or "run the
pipeline" on a pyramid still. It handles the pair together; for one half only,
call the individual script.

## How to run it

```bash
scripts/pipeline.sh <input_image> <output_image>
```

Stage 1 fills the star and its ground shadow with the background colour
`#EFE9DF`. Stage 2 transposes what is left, so a 502x460 input leaves as
460x502. The intermediate goes to a temp directory and is removed on exit.

## Rules

- **Run the script. Do not rewrite what it does as a fresh `convert` call.**
  The polygon coordinates in `scripts/remove_star.sh` were traced against one
  specific image; a regenerated command will not match them.
- **`-transpose`, never `-rotate 90`.** Both turn 502x460 into 460x502, so the
  obvious check passes on either, and they differ in 97024 pixels. The pipeline
  uses `-transpose`.
- **Verify before reporting success.** Run `scripts/verify.sh <input> <output>`.
  It checks the shape, that transposing back reproduces stage 1, and that the
  result is not what `-rotate 90` would have made. Report what it prints.
- Only ImageMagick and bash. No Python.
- If ImageMagick is missing, say so and stop; do not substitute another tool.

## Files

    scripts/remove_star.sh   stage 1, fills the star and shadow
    scripts/transpose.sh     stage 2, mirrors across the diagonal
    scripts/pipeline.sh      both stages, one command
