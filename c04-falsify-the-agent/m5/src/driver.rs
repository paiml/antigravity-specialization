//! A step driver: click a control, then read the state back.
//!
//! Each step names a control and what must be true after the click. The
//! check reads the recorder's state, not the button text.

use crate::page::{ClickError, Page};
use crate::ui::Phase;

/// What must hold after a step.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Expect {
    /// The recorder is in this phase.
    Phase(Phase),
    /// This many takes are recorded.
    Takes(u32),
    /// This many takes are saved.
    Saved(u32),
    /// The status line reads exactly this. A label, not state.
    Status(&'static str),
}

/// One click and its check.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Step {
    /// The control to click.
    pub control: &'static str,
    /// What must hold afterwards.
    pub expect: Expect,
}

/// The first step that did not hold.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Failure {
    /// Index of the step, from 0.
    pub step: usize,
    /// The control it clicked.
    pub control: &'static str,
    /// What went wrong, in words.
    pub reason: String,
}

/// Run `steps` against `page`. Ok holds the number of steps that passed.
pub fn drive(page: &mut Page, steps: &[Step]) -> Result<usize, Failure> {
    for (index, step) in steps.iter().enumerate() {
        let fail = |reason: String| Failure {
            step: index,
            control: step.control,
            reason,
        };
        page.click(step.control).map_err(|err| match err {
            ClickError::Unknown(id) => fail(format!("no control with id {id}")),
            ClickError::Refused(r) => fail(format!("{:?} refused in {:?}", r.action, r.phase)),
        })?;
        let ui = &page.ui;
        let held = match step.expect {
            Expect::Phase(phase) => ui.phase == phase,
            Expect::Takes(n) => ui.takes == n,
            Expect::Saved(n) => ui.saved == n,
            Expect::Status(text) => ui.status == text,
        };
        if !held {
            return Err(fail(format!(
                "expected {:?}, read back {:?}",
                step.expect, ui
            )));
        }
    }
    Ok(steps.len())
}

/// The script that drives every control on the recorder page once.
pub fn recorder_script() -> Vec<Step> {
    vec![
        Step {
            control: "record",
            expect: Expect::Phase(Phase::Recording),
        },
        Step {
            control: "stop",
            expect: Expect::Takes(1),
        },
        Step {
            control: "save",
            expect: Expect::Saved(1),
        },
    ]
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::page::Handler;

    #[test]
    fn the_recorder_script_passes_on_the_wired_page() {
        let mut page = Page::recorder();
        assert_eq!(drive(&mut page, &recorder_script()), Ok(3));
    }

    #[test]
    fn a_dead_control_fails_its_read_back() {
        let mut page = Page::recorder().with_handler("record", Handler::Dead);
        let err = drive(&mut page, &recorder_script()).unwrap_err();
        assert_eq!((err.step, err.control), (0, "record"));
        assert!(
            err.reason.starts_with("expected Phase(Recording)"),
            "{}",
            err.reason
        );
    }

    #[test]
    fn unknown_and_refused_clicks_fail_with_a_reason() {
        let mut page = Page::recorder();
        let missing = [Step {
            control: "nope",
            expect: Expect::Takes(0),
        }];
        assert_eq!(
            drive(&mut page, &missing).unwrap_err().reason,
            "no control with id nope"
        );
        let early = [Step {
            control: "stop",
            expect: Expect::Takes(1),
        }];
        assert_eq!(
            drive(&mut page, &early).unwrap_err().reason,
            "Stop refused in Idle"
        );
    }

    #[test]
    fn a_status_check_reads_the_label() {
        let mut page = Page::recorder();
        let steps = [Step {
            control: "record",
            expect: Expect::Status("Recording"),
        }];
        assert_eq!(drive(&mut page, &steps), Ok(1));
    }
}
