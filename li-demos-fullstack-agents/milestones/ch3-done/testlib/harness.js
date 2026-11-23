'use strict';
// Test harness: a real Taskpad server on an ephemeral port with an in-memory database.
const { openDb } = require('../db');
const { createServer } = require('../server');

const TOKEN = 'test-token';

async function boot() {
  const db = openDb(':memory:');
  const server = createServer({ db, token: TOKEN });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  server.unref(); // a failing assertion must not leave the process hanging on an open server
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = (method, path, { body, auth = true, raw } = {}) =>
    fetch(base + path, {
      method,
      headers: { 'content-type': 'application/json', ...(auth ? { authorization: `Bearer ${TOKEN}` } : {}) },
      body: raw !== undefined ? raw : body === undefined ? undefined : JSON.stringify(body),
    });
  const close = () => new Promise((r) => { server.closeAllConnections(); server.close(r); db.close(); });
  return { base, call, close, db, TOKEN };
}

module.exports = { boot, TOKEN };
