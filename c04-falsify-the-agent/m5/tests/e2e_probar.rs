//! Probar end to end: drive every control of the wasm page in headless Chrome
//! and read the state back from the page itself.
//!
//! Provable contract: for every scripted click, the browser's `#status` text
//! and `data-state` equal what the Rust model [`m5::page::Page`] predicts, and
//! every wired control in the model is clicked at least once.
//!
//! Needs two environment variables (set by `m5/scripts/e2e.sh`):
//! `M5_WEB_DIR`, a directory holding wasm-bindgen's `m5.js` and `m5_bg.wasm`,
//! and `M5_CHROME`, the path of a headless Chrome binary.

use std::collections::BTreeSet;
use std::io::{BufRead, BufReader, Write};
use std::net::TcpListener;
use std::path::{Path, PathBuf};
use std::time::Duration;

use jugar_probar::{Browser, BrowserConfig, Page as ProbarPage};
use m5::page::{boot_js, served_html, Handler, Page, BOOT_FILE};

/// Serve `dir` on 127.0.0.1 from a background thread. `/` is the page.
/// Chrome refuses ES modules from `file://`, so a test needs HTTP.
fn serve(dir: PathBuf) -> u16 {
    let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
    let port = listener.local_addr().expect("addr").port();
    std::thread::spawn(move || {
        for stream in listener.incoming().flatten() {
            let mut stream = stream;
            let mut line = String::new();
            if BufReader::new(&stream).read_line(&mut line).is_err() {
                continue;
            }
            let path = line.split_whitespace().nth(1).unwrap_or("/");
            let (body, kind) = resolve(&dir, path);
            let head = match &body {
                Some(b) => format!(
                    "HTTP/1.1 200 OK\r\nContent-Type: {kind}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                    b.len()
                ),
                None => "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                    .to_string(),
            };
            let _ = stream.write_all(head.as_bytes());
            if let Some(b) = body {
                let _ = stream.write_all(&b);
            }
        }
    });
    port
}

fn resolve(dir: &Path, path: &str) -> (Option<Vec<u8>>, &'static str) {
    match path {
        "/" | "/index.html" => (Some(served_html().into_bytes()), "text/html"),
        p if p == format!("/{BOOT_FILE}") => {
            (Some(boot_js("m5.js").into_bytes()), "text/javascript")
        }
        "/m5.js" => (std::fs::read(dir.join("m5.js")).ok(), "text/javascript"),
        "/m5_bg.wasm" => (
            std::fs::read(dir.join("m5_bg.wasm")).ok(),
            "application/wasm",
        ),
        _ => (None, "text/plain"),
    }
}

/// Read `#status` text and its `data-state` attribute from the live page.
async fn read_back(page: &ProbarPage) -> (String, String) {
    let cdp = page.cdp_page().await.expect("real browser page");
    let el = cdp.find_element("#status").await.expect("#status exists");
    let text = el
        .inner_text()
        .await
        .expect("inner_text")
        .unwrap_or_default();
    let state = el
        .attribute("data-state")
        .await
        .expect("attribute")
        .unwrap_or_default();
    (text, state)
}

/// Poll until the wasm `start` export has drawn the controls.
async fn wait_for_controls(page: &ProbarPage) {
    for _ in 0..100 {
        if let Some(cdp) = page.cdp_page().await {
            if cdp.find_element("#save").await.is_ok() {
                return;
            }
        }
        tokio::time::sleep(Duration::from_millis(100)).await;
    }
    panic!("wasm start never drew #save");
}

#[tokio::test(flavor = "multi_thread")]
async fn every_control_is_driven_and_read_back() {
    let web = PathBuf::from(std::env::var("M5_WEB_DIR").expect("M5_WEB_DIR"));
    let chrome = std::env::var("M5_CHROME").expect("M5_CHROME");
    assert!(web.join("m5_bg.wasm").is_file(), "no m5_bg.wasm in {web:?}");
    let port = serve(web);

    let config = BrowserConfig::default()
        .with_headless(true)
        .with_chromium_path(chrome);
    let browser = Browser::launch(config).await.expect("launch chrome");
    let mut page = browser.new_page().await.expect("new page");
    page.goto(&format!("http://127.0.0.1:{port}/"))
        .await
        .expect("goto");
    wait_for_controls(&page).await;

    // The model the browser must agree with.
    let mut model = Page::recorder();
    let (text, state) = read_back(&page).await;
    assert_eq!(text, model.ui.status);
    assert_eq!(state, model.ui.state_line());

    // Save before Stop is refused; then the happy path; then a second save
    // of the same take is refused. Every click is read back.
    let script = ["save", "record", "stop", "save", "save", "record", "stop"];
    let mut clicked = BTreeSet::new();
    for id in script {
        page.click(&format!("#{id}")).await.expect("click");
        let _ = model.click(id);
        let (text, state) = read_back(&page).await;
        println!("click #{id}: status={text:?} data-state={state:?}");
        assert_eq!(text, model.ui.status, "status after #{id}");
        assert_eq!(state, model.ui.state_line(), "state after #{id}");
        clicked.insert(id);
    }

    let wired: BTreeSet<&str> = model
        .controls
        .iter()
        .filter(|c| matches!(c.handler, Handler::Wired(_)))
        .map(|c| c.id)
        .collect();
    assert!(
        wired.is_subset(&clicked),
        "unclicked: {wired:?} vs {clicked:?}"
    );
    assert_eq!(model.ui.state_line(), "phase=Stopped takes=2 saved=1");

    browser.close().await.expect("close");
    println!(
        "contract: e2e-every-control-read-back OK ({} clicks, {} controls)",
        script.len(),
        wired.len()
    );
}
