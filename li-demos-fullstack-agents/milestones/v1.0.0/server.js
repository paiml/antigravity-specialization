'use strict';
// Taskpad HTTP server: node:http only, no dependencies.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { STATUSES } = require('./db');

const MAX_BODY = 64 * 1024;
const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
};

// validateTitle: trimmed, 1 to 120 characters.
function validateTitle(raw) {
  if (typeof raw !== 'string') return { error: 'title must be a string' };
  const value = raw.trim();
  if (value.length < 1 || value.length > 120) return { error: 'title must be 1 to 120 characters' };
  return { value };
}

// tokenOk: constant-time compare of sha256 digests, so length does not leak either.
function tokenOk(header, token) {
  const m = /^Bearer (.+)$/.exec(header || '');
  if (!m) return false;
  const a = crypto.createHash('sha256').update(m[1]).digest();
  const b = crypto.createHash('sha256').update(token).digest();
  return crypto.timingSafeEqual(a, b);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (c) => {
      size += c.length;
      if (size > MAX_BODY) {
        reject(Object.assign(new Error('body too large'), { status: 413 }));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'));
      } catch {
        reject(Object.assign(new Error('invalid JSON'), { status: 400 }));
      }
    });
  });
}

function createServer({ db, token, publicDir = path.join(__dirname, 'public'), log = () => {} }) {
  if (!token) throw new Error('TASKPAD_TOKEN is required');

  function send(res, status, body) {
    const text = body === undefined ? '' : JSON.stringify(body);
    res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'content-length': Buffer.byteLength(text) });
    res.end(text);
    return status;
  }

  function serveStatic(res, pathname) {
    const rel = pathname === '/' ? 'index.html' : pathname.slice(1);
    const file = path.resolve(publicDir, rel);
    if (!file.startsWith(path.resolve(publicDir) + path.sep) || !TYPES[path.extname(file)] || !fs.existsSync(file)) {
      return send(res, 404, { error: 'not found' });
    }
    const data = fs.readFileSync(file);
    res.writeHead(200, { 'content-type': TYPES[path.extname(file)], 'content-length': data.length });
    res.end(data);
    return 200;
  }

  function listTasks(url, res) {
    const status = url.searchParams.get('status');
    if (status !== null && !STATUSES.includes(status)) return send(res, 400, { error: 'bad status' });
    return send(res, 200, db.list(status));
  }

  async function createTask(req, res) {
    const t = validateTitle((await readBody(req)).title);
    if (t.error) return send(res, 400, { error: t.error });
    return send(res, 201, db.create(t.value));
  }

  // parsePatch: the fields of a PATCH body that may change, or an error message.
  function parsePatch(body) {
    const patch = {};
    if (body.title !== undefined) {
      const t = validateTitle(body.title);
      if (t.error) return { error: t.error };
      patch.title = t.value;
    }
    if (body.status !== undefined) {
      if (!STATUSES.includes(body.status)) return { error: 'bad status' };
      patch.status = body.status;
    }
    if (Object.keys(patch).length === 0) return { error: 'nothing to update' };
    return { patch };
  }

  async function updateTask(req, res, id) {
    const parsed = parsePatch(await readBody(req));
    if (parsed.error) return send(res, 400, { error: parsed.error });
    return send(res, 200, db.update(id, parsed.patch));
  }

  async function api(req, res, url) {
    const m = /^\/api\/tasks(?:\/([^/]+))?$/.exec(url.pathname);
    if (!m) return send(res, 404, { error: 'not found' });
    const id = m[1];
    if (id === undefined && req.method === 'GET') return listTasks(url, res);
    const allowed = id === undefined ? ['POST'] : ['PATCH', 'DELETE'];
    if (!allowed.includes(req.method)) return send(res, 405, { error: 'method not allowed' });
    if (!tokenOk(req.headers.authorization, token)) return send(res, 401, { error: 'unauthorized' });
    if (id === undefined) return createTask(req, res);
    const n = /^[0-9]+$/.test(id) ? Number(id) : NaN;
    if (!db.get(n)) return send(res, 404, { error: 'no such task' });
    if (req.method === 'DELETE') {
      db.remove(n);
      return send(res, 204);
    }
    return updateTask(req, res, n);
  }

  return http.createServer(async (req, res) => {
    const started = Date.now();
    const url = new URL(req.url, 'http://localhost');
    let status;
    try {
      if (url.pathname === '/healthz' && req.method === 'GET') status = send(res, 200, { status: 'ok' });
      else if (url.pathname.startsWith('/api/')) status = await api(req, res, url);
      else if (req.method === 'GET') status = serveStatic(res, url.pathname);
      else status = send(res, 405, { error: 'method not allowed' });
    } catch (e) {
      status = send(res, e.status || 500, { error: e.status ? e.message : 'internal error' });
    }
    log({ method: req.method, path: url.pathname, status, ms: Date.now() - started });
  });
}

module.exports = { createServer, validateTitle, tokenOk };
