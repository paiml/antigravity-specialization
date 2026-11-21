//! A curl-style check: one HTTP GET over loopback, status and body.
//!
//! This is what "it returns 200" measures. It reads bytes. It clicks nothing.

use std::io::{self, BufRead, BufReader, Read, Write};
use std::net::{SocketAddr, TcpListener, TcpStream};

/// Accept one connection and read its request head up to the blank line.
fn accept_request(listener: &TcpListener) -> io::Result<TcpStream> {
    let (stream, _) = listener.accept()?;
    let mut reader = BufReader::new(stream);
    let mut line = String::new();
    while reader.read_line(&mut line)? > 0 && line != "\r\n" {
        line.clear();
    }
    Ok(reader.into_inner())
}

/// Answer one request on `listener` with `200 OK` and `body`.
pub fn serve_once(listener: &TcpListener, body: &str) -> io::Result<()> {
    let mut stream = accept_request(listener)?;
    let reply = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        body.len(),
        body
    );
    stream.write_all(reply.as_bytes())?;
    stream.flush()
}

/// GET `/` from `addr`; return the status code and the body.
pub fn get(addr: SocketAddr) -> io::Result<(u16, String)> {
    let mut stream = TcpStream::connect(addr)?;
    let request = format!("GET / HTTP/1.1\r\nHost: {addr}\r\nConnection: close\r\n\r\n");
    stream.write_all(request.as_bytes())?;
    let mut raw = String::new();
    stream.read_to_string(&mut raw)?;
    let (head, body) = raw.split_once("\r\n\r\n").unwrap_or((raw.as_str(), ""));
    let status = head
        .split_whitespace()
        .nth(1)
        .and_then(|code| code.parse().ok())
        .unwrap_or(0);
    Ok((status, body.to_string()))
}

/// The curl verdict: status 200 and every id present in the body.
pub fn curl_says_ok(status: u16, body: &str, ids: &[&str]) -> bool {
    status == 200 && ids.iter().all(|id| body.contains(&format!("id=\"{id}\"")))
}

/// Serve `body` once on a fresh loopback port and GET it back.
pub fn round_trip(body: &str) -> io::Result<(u16, String)> {
    let listener = TcpListener::bind("127.0.0.1:0")?;
    let addr = listener.local_addr()?;
    std::thread::scope(|scope| {
        let server = scope.spawn(|| serve_once(&listener, body));
        let got = get(addr);
        server.join().expect("server thread")?;
        got
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_returns_200_and_the_body() {
        let (status, body) = round_trip("<button id=\"save\">Save</button>").unwrap();
        assert_eq!(status, 200);
        assert!(curl_says_ok(status, &body, &["save"]));
        assert!(!curl_says_ok(status, &body, &["stop"]));
        assert!(!curl_says_ok(404, &body, &["save"]));
    }

    #[test]
    fn a_reply_with_no_status_line_reads_as_zero() {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let addr = listener.local_addr().unwrap();
        let server = std::thread::spawn(move || {
            let mut stream = accept_request(&listener).unwrap();
            stream.write_all(b"garbage").unwrap();
        });
        let (status, body) = get(addr).unwrap();
        server.join().unwrap();
        assert_eq!((status, body.as_str()), (0, ""));
    }
}
