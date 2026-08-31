# Rust Batch Runner CLI

This document outlines the implementation plan for a Rust CLI designed to orchestrate image processing tasks, as discussed in the design interview.

## Goal Description

Create a Rust-based command-line tool that augments existing bash image processing pipelines by acting as a robust, concurrent task orchestrator. It will replace fragile bash loops, managing the parallel execution of subprocesses (like ImageMagick or FFmpeg), providing a TUI progress bar, aggregating logs into a file, and handling individual file failures gracefully without stopping the entire batch.

## User Review Required

- **Project Name & Location**: The plan proposes creating the project in a new folder called `batch-runner`. Is this acceptable, or do you have a specific name in mind?
- **Command Template Syntax**: The plan proposes using `{}` as the placeholder for the file path in the `--cmd` argument (e.g., `--cmd "magick {} -resize 50% out/{}"`). Let me know if you prefer a different syntax.
- **Log File**: By default, I will create a `batch-runner.log` file in the current working directory. Does this work for you?

## Proposed Changes

### `batch-runner` (New Rust Binary Project)

I will initialize a new Rust project using `cargo new batch-runner` and add the necessary dependencies.

#### [NEW] `batch-runner/Cargo.toml`
Will include dependencies:
- `clap`: For parsing command-line arguments (`--dir`, `--cmd`, `--jobs`).
- `rayon`: For easy and efficient thread-pool based parallelization.
- `indicatif`: For rendering the TUI progress bar.
- `walkdir` or `ignore`: To recursively traverse the target directory and find files.

#### [NEW] `batch-runner/src/main.rs`
The main entry point will handle:
- Parsing CLI arguments.
- Setting up the Rayon thread pool based on the `--jobs` argument (defaulting to available CPUs).
- Initializing the progress bar and the log file.
- Traversing the input directory to build a list of target files.
- Executing the worker logic in parallel.
- Returning an appropriate exit code based on whether any tasks failed.

#### [NEW] `batch-runner/src/worker.rs`
Will contain the logic for a single task:
- Replacing the `{}` placeholder in the command template with the actual file path.
- Spawning the subprocess using `std::process::Command`.
- Capturing `stdout` and `stderr`.
- Returning a `Result` containing the captured logs or the error context.

## Verification Plan

### Automated Tests
- I will write unit tests for the command template substitution logic in `worker.rs`.

### Manual Verification
- We will build the CLI and run it against a dummy directory with a simple `sleep` and `echo` command template to verify the progress bar, concurrency, and log file generation.
- Then, we can test it with your actual image processing pipeline if you have sample files available.
