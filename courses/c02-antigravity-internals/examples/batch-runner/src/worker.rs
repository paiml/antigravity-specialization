use std::path::Path;
use std::process::{Command, Output};
use shell_words::split;

#[derive(Debug)]
pub enum WorkerError {
    ParseError(shell_words::ParseError),
    EmptyCommand,
    IoError(std::io::Error),
    ExecutionError(Output),
}

pub fn execute_task(cmd_template: &str, file_path: &Path) -> Result<Output, WorkerError> {
    // Parse the command template into arguments
    let mut args = split(cmd_template).map_err(WorkerError::ParseError)?;
    
    if args.is_empty() {
        return Err(WorkerError::EmptyCommand);
    }

    let file_str = file_path.to_string_lossy().into_owned();

    // Replace "{}" with the actual file path in all arguments
    for arg in args.iter_mut() {
        if arg.contains("{}") {
            *arg = arg.replace("{}", &file_str);
        }
    }

    let program = args.remove(0);

    // Execute the command
    let output = Command::new(program)
        .args(args)
        .output()
        .map_err(WorkerError::IoError)?;

    if output.status.success() {
        Ok(output)
    } else {
        Err(WorkerError::ExecutionError(output))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_execute_task_echo() {
        let path = Path::new("test_file.txt");
        let result = execute_task("echo {}", path).unwrap();
        let stdout = String::from_utf8_lossy(&result.stdout);
        assert_eq!(stdout.trim(), "test_file.txt");
    }

    #[test]
    fn test_execute_task_multiple_replacements() {
        let path = Path::new("image.png");
        let result = execute_task("echo {} out/{}", path).unwrap();
        let stdout = String::from_utf8_lossy(&result.stdout);
        assert_eq!(stdout.trim(), "image.png out/image.png");
    }
}
