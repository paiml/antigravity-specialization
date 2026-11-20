//! The Save control's contract, as code: precondition and postcondition.
//!
//! `contracts/record-ui-v1.yaml` states the same two rules for `pv`. These
//! functions are what the falsification test and the demo bin check.

use crate::ui::{Phase, RecordUi};

/// Save may run only after a take ended and while some take is unsaved.
pub fn save_pre(ui: &RecordUi) -> bool {
    ui.phase == Phase::Stopped && ui.takes > ui.saved
}

/// After Save: every take is saved, the phase and take count are unchanged,
/// and the status line reads "Saved".
pub fn save_post(before: &RecordUi, after: &RecordUi) -> bool {
    after.saved == before.takes
        && after.takes == before.takes
        && after.phase == before.phase
        && after.status == "Saved"
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::Action;

    fn stopped_with_one_take() -> RecordUi {
        let mut ui = RecordUi::new();
        ui.apply(Action::Record).unwrap();
        ui.apply(Action::Stop).unwrap();
        ui
    }

    #[test]
    fn save_meets_its_postcondition_when_the_precondition_holds() {
        let before = stopped_with_one_take();
        assert!(save_pre(&before));
        let mut after = before.clone();
        after.apply(Action::Save).unwrap();
        assert!(save_post(&before, &after));
    }

    #[test]
    fn save_is_refused_and_changes_nothing_when_the_precondition_fails() {
        let mut idle = RecordUi::new();
        assert!(!save_pre(&idle));
        let before = idle.clone();
        assert!(idle.apply(Action::Save).is_err());
        assert_eq!(idle, before);
    }

    #[test]
    fn a_label_without_state_breaks_the_postcondition() {
        let before = stopped_with_one_take();
        let mut fake = before.clone();
        fake.status = "Saved".to_string();
        assert!(!save_post(&before, &fake));
    }
}
