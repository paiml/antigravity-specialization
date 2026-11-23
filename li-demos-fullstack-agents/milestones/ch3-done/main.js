'use strict';
// Entry point: reads PORT, HOST, DB_PATH, TASKPAD_TOKEN, NODE_ENV. Logs one JSON line per request to stderr.
const { openDb } = require('./db');
const { createServer } = require('./server');

const production = process.env.NODE_ENV === 'production';
let token = process.env.TASKPAD_TOKEN;
if (!token) {
  if (production) {
    console.error('refusing to start: TASKPAD_TOKEN is required when NODE_ENV=production');
    process.exit(1);
  }
  token = 'dev-token';
  console.error('warning: TASKPAD_TOKEN not set, using the development token');
}
const db = openDb(process.env.DB_PATH || 'data/taskpad.db');
const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '127.0.0.1';
createServer({ db, token, log: (e) => console.error(JSON.stringify(e)) }).listen(port, host, () => {
  console.log(`taskpad listening on http://${host}:${port}`);
});
