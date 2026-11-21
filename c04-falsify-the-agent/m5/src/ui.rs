//! The recorder state machine behind the page.
//!
//! The page is a view of this state. A click is an [`Action`]; the state
//! machine either moves or refuses, and a refused action changes nothing.

/// Where the recorder is.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Phase {
    /// Nothing is recording.
    #[default]
    Idle,
    /// A take is being recorded.
    Recording,
    /// A take has ended.
    Stopped,
}

/// One thing a control can ask the recorder to do.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    /// Start a take.
    Record,
    /// End the take.
    Stop,
    /// Keep every take recorded so far.
    Save,
}

/// Why an action was refused.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Refused {
    /// The action that was refused.
    pub action: Action,
    /// The phase the recorder was in.
    pub phase: Phase,
}

/// The recorder's whole state. Equality is the read-back check.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct RecordUi {
    /// The current phase.
    pub phase: Phase,
    /// Takes recorded so far.
    pub takes: u32,
    /// Takes saved so far. Saved is state; the status line is only a label.
    pub saved: u32,
    /// The status line the page shows.
    pub status: String,
}

impl RecordUi {
    /// A fresh recorder: idle, no takes, status "Ready".
    pub fn new() -> Self {
        Self {
            status: "Ready".to_string(),
            ..Self::default()
        }
    }

    /// Apply one action. A refused action leaves the state as it was.
    pub fn apply(&mut self, action: Action) -> Result<(), Refused> {
        let refused = Refused {
            action,
            phase: self.phase,
        };
        match (action, self.phase) {
            (Action::Record, Phase::Idle | Phase::Stopped) => {
                self.phase = Phase::Recording;
                self.status = "Recording".to_string();
                Ok(())
            }
            (Action::Stop, Phase::Recording) => {
                self.phase = Phase::Stopped;
                self.takes += 1;
                self.status = "Stopped".to_string();
                Ok(())
            }
            (Action::Save, Phase::Stopped) if self.takes > self.saved => {
                self.saved = self.takes;
                self.status = "Saved".to_string();
                Ok(())
            }
            _ => Err(refused),
        }
    }

    /// The state as one line, for a browser test to read back.
    ///
    /// The page writes it to the `data-state` attribute of `#status`, so a
    /// test reads state, not the label.
    pub fn state_line(&self) -> String {
        format!(
            "phase={:?} takes={} saved={}",
            self.phase, self.takes, self.saved
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn record_then_stop_counts_one_take() {
        let mut ui = RecordUi::new();
        assert_eq!(ui.status, "Ready");
        ui.apply(Action::Record).unwrap();
        assert_eq!(ui.phase, Phase::Recording);
        ui.apply(Action::Stop).unwrap();
        assert_eq!(
            (ui.phase, ui.takes, ui.status.as_str()),
            (Phase::Stopped, 1, "Stopped")
        );
        ui.apply(Action::Record).unwrap();
        assert_eq!(ui.phase, Phase::Recording);
    }

    #[test]
    fn a_refused_action_changes_nothing() {
        let mut ui = RecordUi::new();
        let before = ui.clone();
        let err = ui.apply(Action::Stop).unwrap_err();
        assert_eq!(
            err,
            Refused {
                action: Action::Stop,
                phase: Phase::Idle
            }
        );
        assert_eq!(ui, before);
        ui.apply(Action::Record).unwrap();
        assert!(ui.apply(Action::Record).is_err());
    }

    #[test]
    fn save_keeps_the_take_once() {
        let mut ui = RecordUi::new();
        assert!(ui.apply(Action::Save).is_err());
        ui.apply(Action::Record).unwrap();
        ui.apply(Action::Stop).unwrap();
        ui.apply(Action::Save).unwrap();
        assert_eq!((ui.saved, ui.status.as_str()), (1, "Saved"));
        let before = ui.clone();
        assert!(ui.apply(Action::Save).is_err());
        assert_eq!(ui, before);
    }

    #[test]
    fn state_line_names_phase_takes_and_saved() {
        let mut ui = RecordUi::new();
        assert_eq!(ui.state_line(), "phase=Idle takes=0 saved=0");
        ui.apply(Action::Record).unwrap();
        ui.apply(Action::Stop).unwrap();
        ui.apply(Action::Save).unwrap();
        assert_eq!(ui.state_line(), "phase=Stopped takes=1 saved=1");
    }
}
