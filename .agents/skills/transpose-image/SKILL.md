---
name: transpose-image
description: Safely transposes an image, mirroring it across the top-left/bottom-right diagonal.
---

# Transpose Image Skill

This skill safely and correctly transposes an image.

## When to use this

Use this skill when the user asks to transpose an image. It ensures the operation is mathematically a transpose (mirroring across the diagonal) and not just a 90-degree rotation.

## How to run it

```bash
scripts/transpose.sh <input_image> <output_image>
```

## Rules

- **Run the script. Do not rewrite what it does as a fresh `convert` call.**
- **Understand the difference between `-transpose` and `-rotate 90`.** They are not the same operation, even though they yield the same output dimensions. `-transpose` mirrors the image; `-rotate 90` turns it.
- **Verify before reporting success.** Run `scripts/verify.sh <input> <output>`. It checks that transposing back reproduces the input, and that the result is not what `-rotate 90` would have made. Report what it prints.
- Only ImageMagick and bash. No Python.
- If ImageMagick is missing, say so and stop.

## Files

    scripts/transpose.sh     performs the transpose operation
    scripts/verify.sh        verifies the correctness of the transpose
