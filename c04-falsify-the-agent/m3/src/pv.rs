//! Runs the `pv` verifier and hands back what it printed and how it exited.

use std::path::Path;
use std::process::Command;

/// What one `pv` call printed on stdout, and its exit code (`-1` when killed by a signal).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PvRun {
    pub stdout: String,
    pub exit: i32,
}

/// Runs `pv` from `PATH` with `args` inside `dir`.
pub fn run(dir: &Path, args: &[&str]) -> Result<PvRun, String> {
    run_with("pv", dir, args)
}

/// Runs the verifier at `bin` with `args` inside `dir`. A verifier that does not start is an error.
pub fn run_with(bin: &str, dir: &Path, args: &[&str]) -> Result<PvRun, String> {
    let out = Command::new(bin)
        .args(args)
        .current_dir(dir)
        .output()
        .map_err(|e| format!("{bin} did not start: {e}"))?;
    Ok(PvRun {
        stdout: String::from_utf8_lossy(&out.stdout).into_owned(),
        exit: out.status.code().unwrap_or(-1),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_missing_verifier_is_an_error_not_a_pass() {
        let err = run_with("/nonexistent/pv", Path::new("."), &["--version"]).unwrap_err();
        assert!(err.contains("did not start"), "{err}");
    }

    #[test]
    fn a_signal_exit_reads_as_minus_one() {
        let r = run_with("sh", Path::new("."), &["-c", "kill -9 $$"]).unwrap();
        assert_eq!(r.exit, -1);
    }

    #[test]
    fn the_real_verifier_reports_its_version() {
        let r = run(Path::new("."), &["--version"]).unwrap();
        assert_eq!(r.exit, 0);
        assert!(r.stdout.starts_with("pv "), "{}", r.stdout);
    }
}
