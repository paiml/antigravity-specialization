ALTER TABLE tasks ADD COLUMN updated_at TEXT;
UPDATE tasks SET updated_at = created_at;
