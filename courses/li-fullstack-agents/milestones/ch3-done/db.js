'use strict';
// Taskpad data layer: node:sqlite (experimental, prints a warning) plus a tiny migration runner.
const fs = require('node:fs');
const path = require('node:path');
const { DatabaseSync } = require('node:sqlite');

const STATUSES = ['todo', 'doing', 'done'];
const MIGRATIONS_DIR = path.join(__dirname, 'migrations');

function migrate(db) {
  db.exec('CREATE TABLE IF NOT EXISTS schema_migrations (name TEXT PRIMARY KEY)');
  const applied = new Set(db.prepare('SELECT name FROM schema_migrations').all().map((r) => r.name));
  const files = fs.readdirSync(MIGRATIONS_DIR).filter((f) => f.endsWith('.sql')).sort();
  const done = [];
  for (const file of files) {
    if (applied.has(file)) continue;
    db.exec('BEGIN');
    db.exec(fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8'));
    db.prepare('INSERT INTO schema_migrations (name) VALUES (?)').run(file);
    db.exec('COMMIT');
    done.push(file);
  }
  return done;
}

function openDb(file) {
  if (file !== ':memory:') fs.mkdirSync(path.dirname(path.resolve(file)), { recursive: true });
  const db = new DatabaseSync(file);
  migrate(db);
  const now = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";
  const q = {
    all: db.prepare('SELECT * FROM tasks ORDER BY id'),
    byStatus: db.prepare('SELECT * FROM tasks WHERE status = ? ORDER BY id'),
    get: db.prepare('SELECT * FROM tasks WHERE id = ?'),
    insert: db.prepare(`INSERT INTO tasks (title, updated_at) VALUES (?, ${now})`),
    update: db.prepare(`UPDATE tasks SET title = ?, status = ?, updated_at = ${now} WHERE id = ?`),
    remove: db.prepare('DELETE FROM tasks WHERE id = ?'),
  };
  return {
    raw: db,
    list: (status) => (status ? q.byStatus.all(status) : q.all.all()),
    get: (id) => q.get.get(id),
    create: (title) => q.get.get(q.insert.run(title).lastInsertRowid),
    update(id, patch) {
      const cur = q.get.get(id);
      q.update.run(patch.title ?? cur.title, patch.status ?? cur.status, id);
      return q.get.get(id);
    },
    remove: (id) => q.remove.run(id).changes > 0,
    close: () => db.close(),
  };
}

module.exports = { openDb, migrate, STATUSES };
