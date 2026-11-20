//! The wasm-bindgen layer: the page's only code in the browser.
//!
//! Compiled for `wasm32` only. Each `#[wasm_bindgen]` export is one control's
//! click handler; `start` draws the page and wires each button to its export.
//! No hand-written JavaScript: wasm-bindgen generates the glue.

use std::cell::RefCell;

use wasm_bindgen::prelude::*;

use crate::page::{Handler, Page};
use crate::ui::Action;

thread_local! {
    static PAGE: RefCell<Page> = RefCell::new(Page::recorder());
}

fn act(action: Action) {
    PAGE.with(|page| {
        let mut page = page.borrow_mut();
        // A refused action leaves the state as it was; the status line shows it.
        let _ = page.ui.apply(action);
        set_status(&page.ui.status, &page.ui.state_line());
    });
}

fn set_status(text: &str, state: &str) {
    if let Some(el) = web_sys::window()
        .and_then(|w| w.document())
        .and_then(|d| d.get_element_by_id("status"))
    {
        el.set_text_content(Some(text));
        let _ = el.set_attribute("data-state", state);
    }
}

/// Record button.
#[wasm_bindgen]
pub fn record() {
    act(Action::Record);
}

/// Stop button.
#[wasm_bindgen]
pub fn stop() {
    act(Action::Stop);
}

/// Save button.
#[wasm_bindgen]
pub fn save() {
    act(Action::Save);
}

/// Draw the page and wire each wired control to its export.
#[wasm_bindgen(start)]
pub fn start() -> Result<(), JsValue> {
    let document = web_sys::window()
        .and_then(|w| w.document())
        .ok_or_else(|| JsValue::from_str("no document"))?;
    let body = document
        .body()
        .ok_or_else(|| JsValue::from_str("no body"))?;
    let html = PAGE.with(|page| page.borrow().html());
    body.set_inner_html(&html);
    PAGE.with(|page| {
        let page = page.borrow();
        set_status(&page.ui.status, &page.ui.state_line());
    });
    let controls = PAGE.with(|page| page.borrow().controls.clone());
    for control in controls {
        let Handler::Wired(action) = control.handler else {
            continue;
        };
        let Some(button) = document.get_element_by_id(control.id) else {
            continue;
        };
        let on_click = Closure::<dyn FnMut()>::new(move || act(action));
        button.add_event_listener_with_callback("click", on_click.as_ref().unchecked_ref())?;
        on_click.forget();
    }
    Ok(())
}
