# Plan: Implement a Transpose Image Skill

This document outlines the plan to build a new agent skill specifically designed for transposing images using ImageMagick. 

## Objective
Create a project-local skill named `transpose-image` that allows the agent to safely and correctly transpose an image, adhering to the project's strict definitions of what a transpose operation entails.

## Planned Steps

### 1. Skill Directory Structure
Create a new directory structure for the skill, for example:
```
.agents/skills/transpose-image/
├── SKILL.md
└── scripts/
    ├── transpose.sh
    └── verify.sh
```

### 2. Implement the Bash Scripts
We need to provide the actual ImageMagick execution scripts rather than letting the agent run raw commands.

*   **`scripts/transpose.sh`**: A focused bash script that takes an input and output file, and runs:
    ```bash
    convert "$1" -transpose "$2"
    ```
*   **`scripts/verify.sh`**: A verification script to ensure the image was manipulated correctly. It must verify that:
    1.  The output image dimensions are swapped compared to the input.
    2.  Applying `-transpose` a second time to the output exactly reproduces the input image.
    3.  The output is *not* what `-rotate 90` would produce, as `-transpose` mirrors across the diagonal, while `-rotate 90` spins the image.

### 3. Write `SKILL.md`
The `SKILL.md` file defines how the agent should use the scripts. The plan is to include the following rules and instructions:

*   **Name**: `transpose-image`
*   **Description**: Safely transposes an image, mirroring it across the top-left/bottom-right diagonal.
*   **Execution**: Instruct the agent to run `scripts/transpose.sh <input> <output>` when asked to transpose an image.
*   **Rules**:
    *   **NEVER** rewrite the `convert` command manually; always use the provided script.
    *   Understand the difference between `-transpose` and `-rotate 90`. They are not the same operation, even though they yield the same output dimensions.
    *   **ALWAYS** verify the result by running `scripts/verify.sh <input> <output>` before reporting success to the user.

## Why this approach?
By packaging the transpose operation as a defined skill with accompanying bash scripts, we prevent the agent from accidentally using `-rotate 90` or hallucinating incorrect ImageMagick syntax. The `verify.sh` step guarantees that the mathematical properties of a true transpose (involution) hold true for the output.
