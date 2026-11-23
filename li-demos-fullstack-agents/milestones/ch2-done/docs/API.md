# API

Base URL: `http://127.0.0.1:3000`. Bodies are JSON. Errors look like `{"error": "message"}`.
Write requests need the header `Authorization: Bearer $TASKPAD_TOKEN`.

A task is `{"id": 1, "title": "...", "status": "todo", "created_at": "...", "updated_at": "..."}`.

## GET /healthz

```
curl -s http://127.0.0.1:3000/healthz
{"status":"ok"}
```

## GET /api/tasks

Optional `?status=todo|doing|done`. A bad status is 400.

```
curl -s 'http://127.0.0.1:3000/api/tasks?status=doing'
```

## POST /api/tasks

Body `{"title": "..."}`, 1 to 120 characters after trimming. Returns 201 and the task. 400 for a bad title, 401 without the token.

```
curl -s -X POST http://127.0.0.1:3000/api/tasks \
  -H "Authorization: Bearer $TASKPAD_TOKEN" -H 'content-type: application/json' \
  -d '{"title":"write the spec"}'
```

## PATCH /api/tasks/:id

Body with `title` and/or `status`. Returns 200 and the task. 400 for bad input or an empty body, 401 without the token, 404 for an unknown id.

```
curl -s -X PATCH http://127.0.0.1:3000/api/tasks/1 \
  -H "Authorization: Bearer $TASKPAD_TOKEN" -H 'content-type: application/json' \
  -d '{"status":"doing"}'
```

## DELETE /api/tasks/:id

Returns 204. 401 without the token, 404 for an unknown id.

```
curl -s -X DELETE http://127.0.0.1:3000/api/tasks/1 -H "Authorization: Bearer $TASKPAD_TOKEN"
```
