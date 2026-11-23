'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { openDb, migrate } = require('../db');

test('migrations apply once, in order, and are recorded', () => {
  const db = openDb(':memory:');
  const names = db.raw.prepare('SELECT name FROM schema_migrations ORDER BY name').all().map((r) => r.name);
  assert.deepEqual(names, ['001_create_tasks.sql', '002_add_updated_at.sql']);
  assert.deepEqual(migrate(db.raw), []);
  const cols = db.raw.prepare('PRAGMA table_info(tasks)').all().map((c) => c.name);
  assert.deepEqual(cols, ['id', 'title', 'status', 'created_at', 'updated_at']);
  db.close();
});

test('the schema rejects a bad status and an empty title', () => {
  const db = openDb(':memory:');
  assert.throws(() => db.raw.prepare("INSERT INTO tasks (title, status) VALUES ('a', 'bogus')").run());
  assert.throws(() => db.raw.prepare("INSERT INTO tasks (title) VALUES ('')").run());
  db.close();
});

test('a file database is created with its directory and keeps rows', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'taskpad-'));
  const file = path.join(dir, 'sub', 'tp.db');
  let db = openDb(file);
  const row = db.create('kept');
  db.close();
  db = openDb(file);
  assert.equal(db.get(row.id).title, 'kept');
  assert.equal(db.update(row.id, { status: 'done' }).status, 'done');
  assert.equal(db.remove(row.id), true);
  assert.equal(db.remove(row.id), false);
  db.close();
  fs.rmSync(dir, { recursive: true });
});
