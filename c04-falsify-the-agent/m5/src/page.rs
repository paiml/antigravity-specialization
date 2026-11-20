//! The recorder page: a list of controls over a [`RecordUi`].
//!
//! The HTML is what a curl sees. A click is what a browser does. They are not
//! the same thing: a control can be in the HTML and still do nothing.

use crate::ui::{Action, RecordUi, Refused};

/// What a control does when it is clicked.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Handler {
    /// The click reaches the recorder.
    Wired(Action),
    /// The button is drawn but nothing listens to it.
    Dead,
    /// The click rewrites the status line and touches no state.
    StatusOnly(&'static str),
}

/// One button on the page.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Control {
    /// The element id, `id="..."` in the HTML.
    pub id: &'static str,
    /// The button text.
    pub label: &'static str,
    /// What a click does.
    pub handler: Handler,
}

/// Why a click failed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ClickError {
    /// No control has this id.
    Unknown(String),
    /// The recorder refused the action.
    Refused(Refused),
}

/// The page: its controls and the state they act on.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Page {
    /// Controls in page order.
    pub controls: Vec<Control>,
    /// The state behind the page.
    pub ui: RecordUi,
}

impl Page {
    /// The recorder page with every control wired.
    pub fn recorder() -> Self {
        Self {
            controls: vec![
                Control {
                    id: "record",
                    label: "Record",
                    handler: Handler::Wired(Action::Record),
                },
                Control {
                    id: "stop",
                    label: "Stop",
                    handler: Handler::Wired(Action::Stop),
                },
                Control {
                    id: "save",
                    label: "Save",
                    handler: Handler::Wired(Action::Save),
                },
            ],
            ui: RecordUi::new(),
        }
    }

    /// The same page with one control's handler replaced.
    pub fn with_handler(mut self, id: &str, handler: Handler) -> Self {
        for control in &mut self.controls {
            if control.id == id {
                control.handler = handler;
            }
        }
        self
    }

    /// The HTML a server sends for this page.
    pub fn html(&self) -> String {
        let mut out = String::from(
            "<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>Recorder</title></head><body>\n",
        );
        for control in &self.controls {
            out.push_str(&format!(
                "<button id=\"{}\">{}</button>\n",
                control.id, control.label
            ));
        }
        out.push_str(&format!(
            "<p id=\"status\">{}</p>\n</body></html>\n",
            self.ui.status
        ));
        out
    }

    /// Click the control with this id, as a browser would.
    pub fn click(&mut self, id: &str) -> Result<(), ClickError> {
        let control = self
            .controls
            .iter()
            .find(|c| c.id == id)
            .ok_or_else(|| ClickError::Unknown(id.to_string()))?;
        match control.handler {
            Handler::Wired(action) => self.ui.apply(action).map_err(ClickError::Refused),
            Handler::Dead => Ok(()),
            Handler::StatusOnly(text) => {
                self.ui.status = text.to_string();
                Ok(())
            }
        }
    }
}

/// File name of the boot module the served page loads.
pub const BOOT_FILE: &str = "boot.js";

/// The boot module: import the wasm-bindgen glue and call its `init`.
///
/// wasm-bindgen's glue does not start itself; something must call the default
/// export or `#[wasm_bindgen(start)]` never runs. This Rust string is that
/// call. It is generated, never hand-written in a `.js` file.
pub fn boot_js(glue_file: &str) -> String {
    format!("import init from \"./{glue_file}\";\ninit();\n")
}

/// The HTML an HTTP server sends to a browser: an empty body and one module
/// tag. The wasm `start` export draws the controls into the body.
pub fn served_html() -> String {
    format!(
        "<!doctype html>\n<html><head><meta charset=\"utf-8\"><title>Recorder</title>\
<script type=\"module\" src=\"{BOOT_FILE}\"></script></head><body></body></html>\n"
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::Phase;

    #[test]
    fn html_carries_every_control_and_the_status() {
        let html = Page::recorder().html();
        assert!(html.starts_with("<!doctype html>"));
        assert!(html.contains("<button id=\"record\">Record</button>"));
        assert!(html.contains("<button id=\"stop\">Stop</button>"));
        assert!(html.contains("<button id=\"save\">Save</button>"));
        assert!(html.contains("<p id=\"status\">Ready</p>"));
    }

    #[test]
    fn a_wired_click_moves_the_state() {
        let mut page = Page::recorder();
        page.click("record").unwrap();
        assert_eq!(page.ui.phase, Phase::Recording);
        assert!(matches!(page.click("record"), Err(ClickError::Refused(_))));
    }

    #[test]
    fn a_dead_click_succeeds_and_changes_nothing() {
        let mut page = Page::recorder().with_handler("record", Handler::Dead);
        let before = page.ui.clone();
        page.click("record").unwrap();
        assert_eq!(page.ui, before);
    }

    #[test]
    fn a_status_only_click_changes_the_label_and_nothing_else() {
        let mut page = Page::recorder().with_handler("save", Handler::StatusOnly("Saved"));
        page.click("record").unwrap();
        page.click("stop").unwrap();
        page.click("save").unwrap();
        assert_eq!((page.ui.status.as_str(), page.ui.saved), ("Saved", 0));
    }

    #[test]
    fn an_unknown_control_is_an_error() {
        let mut page = Page::recorder();
        assert_eq!(
            page.click("missing"),
            Err(ClickError::Unknown("missing".to_string()))
        );
    }

    #[test]
    fn boot_module_imports_the_glue_and_calls_init() {
        assert_eq!(boot_js("m5.js"), "import init from \"./m5.js\";\ninit();\n");
    }

    #[test]
    fn served_html_loads_the_boot_module_once() {
        let html = served_html();
        assert!(html.starts_with("<!doctype html>"));
        assert_eq!(html.matches("<script").count(), 1);
        assert!(html.contains("<script type=\"module\" src=\"boot.js\"></script>"));
        assert!(!html.contains("<button"));
    }
}
