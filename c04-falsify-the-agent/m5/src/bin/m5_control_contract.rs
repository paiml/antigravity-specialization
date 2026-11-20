//! m5_control_contract: a contract for a control.
//!
//! Provable contract: Save runs only when its precondition holds (a take has
//! ended and is unsaved) and then meets its postcondition (saved equals takes,
//! status reads "Saved"); with the precondition false it is refused and the
//! state is unchanged.

use m5::contract::{save_post, save_pre};
use m5::ui::{Action, RecordUi};

fn main() {
    let mut ui = RecordUi::new();
    let idle = ui.clone();
    let refused = ui.apply(Action::Save);
    println!("idle: pre={} click={refused:?}", save_pre(&idle));

    ui.apply(Action::Record).expect("record");
    ui.apply(Action::Stop).expect("stop");
    let before = ui.clone();
    ui.apply(Action::Save).expect("save");
    println!(
        "stopped: pre={} post={} saved={} status={:?}",
        save_pre(&before),
        save_post(&before, &ui),
        ui.saved,
        ui.status
    );

    assert!(!save_pre(&idle));
    assert!(refused.is_err());
    assert!(save_pre(&before));
    assert!(save_post(&before, &ui));
    println!("contract: record-ui-v1 Save pre and post hold, a failed pre is refused OK");
}
