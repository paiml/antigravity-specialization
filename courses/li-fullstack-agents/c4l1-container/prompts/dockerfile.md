Write a Dockerfile and a .dockerignore for Taskpad. Base image node:22-slim. Copy only what the app needs at run time (no tests, no docs, no scripts).
Run as the non-root `node` user. Keep the database in a /data volume. Set NODE_ENV=production so the server refuses to start without a token.
Add a HEALTHCHECK that calls /healthz with node (the slim image has no curl). Build it, run it with a volume, write a task, restart the container,
and show the task is still there.
