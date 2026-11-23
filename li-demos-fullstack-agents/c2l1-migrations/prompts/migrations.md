Add db.js and two migrations. 001_create_tasks.sql creates `tasks` with id, title (1 to 120 characters, enforced by a CHECK),
status (todo, doing or done, enforced by a CHECK, default todo) and created_at. 002_add_updated_at.sql adds updated_at and fills it for old rows.
db.js applies migrations/*.sql in name order, records each in schema_migrations, and applies nothing twice.
Never edit 001 after it has run: change the schema with a new numbered file. Show me the schema with `sqlite3 FILE .schema`.
