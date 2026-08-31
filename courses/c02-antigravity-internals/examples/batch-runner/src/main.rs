mod worker;

use clap::Parser;
use indicatif::{ProgressBar, ProgressStyle};
use rayon::prelude::*;
use std::fs::File;
use std::io::Write;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use walkdir::WalkDir;
use worker::{execute_task, WorkerError};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Directory containing the files to process
    #[arg(short, long)]
    dir: PathBuf,

    /// Command template to run. Use {} as a placeholder for the file path.
    /// Example: 'magick {} -resize 50% out/{}'
    #[arg(short, long)]
    cmd: String,

    /// Number of concurrent jobs to run (defaults to logical CPU cores)
    #[arg(short, long)]
    jobs: Option<usize>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    // Configure thread pool if jobs is specified
    if let Some(jobs) = args.jobs {
        rayon::ThreadPoolBuilder::new()
            .num_threads(jobs)
            .build_global()?;
    }

    // Collect all file paths (ignoring directories)
    println!("Scanning directory...");
    let files: Vec<PathBuf> = WalkDir::new(&args.dir)
        .into_iter()
        .filter_map(Result::ok)
        .filter(|e| e.file_type().is_file())
        .map(|e| e.into_path())
        .collect();

    if files.is_empty() {
        println!("No files found in the specified directory.");
        return Ok(());
    }

    println!("Found {} files to process.", files.len());

    // Setup progress bar
    let pb = ProgressBar::new(files.len() as u64);
    pb.set_style(
        ProgressStyle::default_bar()
            .template("[{elapsed_precise}] {bar:40.cyan/blue} {pos:>7}/{len:7} {msg}")?
            .progress_chars("##-"),
    );

    // Setup log file
    let log_file = Arc::new(Mutex::new(File::create("batch-runner.log")?));

    // Process files in parallel
    let failures_count = std::sync::atomic::AtomicUsize::new(0);

    files.par_iter().for_each(|file| {
        let result = execute_task(&args.cmd, file);

        let mut log = log_file.lock().unwrap();
        writeln!(
            log,
            "----------------------------------------\nProcessing: {}",
            file.display()
        )
        .unwrap();

        match result {
            Ok(output) => {
                writeln!(log, "Status: Success").unwrap();
                if !output.stdout.is_empty() {
                    writeln!(log, "STDOUT:\n{}", String::from_utf8_lossy(&output.stdout)).unwrap();
                }
                if !output.stderr.is_empty() {
                    writeln!(log, "STDERR:\n{}", String::from_utf8_lossy(&output.stderr)).unwrap();
                }
            }
            Err(e) => {
                failures_count.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                writeln!(log, "Status: FAILED").unwrap();
                match e {
                    WorkerError::ParseError(err) => {
                        writeln!(log, "Error parsing command template: {}", err).unwrap();
                    }
                    WorkerError::EmptyCommand => {
                        writeln!(log, "Error: Command template is empty.").unwrap();
                    }
                    WorkerError::IoError(err) => {
                        writeln!(log, "I/O Error executing command: {}", err).unwrap();
                    }
                    WorkerError::ExecutionError(output) => {
                        writeln!(
                            log,
                            "Command exited with non-zero status: {}",
                            output.status
                        )
                        .unwrap();
                        if !output.stdout.is_empty() {
                            writeln!(log, "STDOUT:\n{}", String::from_utf8_lossy(&output.stdout))
                                .unwrap();
                        }
                        if !output.stderr.is_empty() {
                            writeln!(log, "STDERR:\n{}", String::from_utf8_lossy(&output.stderr))
                                .unwrap();
                        }
                    }
                }
            }
        }
        pb.inc(1);
    });

    pb.finish_with_message("Done!");

    let failures = failures_count.load(std::sync::atomic::Ordering::Relaxed);
    if failures > 0 {
        eprintln!(
            "Finished with {} failures. Check batch-runner.log for details.",
            failures
        );
        std::process::exit(1);
    } else {
        println!("All tasks completed successfully. Logs written to batch-runner.log");
    }

    Ok(())
}
