'use strict';
// Taskpad scaffold: a server that answers /healthz and nothing else yet.
const http = require('node:http');

function createServer({ log = () => {} } = {}) {
  return http.createServer((req, res) => {
    const started = Date.now();
    const ok = req.method === 'GET' && req.url === '/healthz';
    const text = JSON.stringify(ok ? { status: 'ok' } : { error: 'not found' });
    res.writeHead(ok ? 200 : 404, { 'content-type': 'application/json; charset=utf-8' });
    res.end(text);
    log({ method: req.method, path: req.url, status: ok ? 200 : 404, ms: Date.now() - started });
  });
}

module.exports = { createServer };
