'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { boot } = require('../testlib/harness');
const { createServer, validateTitle, tokenOk } = require('../server');
const { openDb } = require('../db');

test('healthz answers ok', async () => {
  const t = await boot();
  const res = await t.call('GET', '/healthz', { auth: false });
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'ok' });
  await t.close();
});

test('create, list, filter, update, delete', async () => {
  const t = await boot();
  let res = await t.call('POST', '/api/tasks', { body: { title: '  write spec  ' } });
  assert.equal(res.status, 201);
  const task = await res.json();
  assert.equal(task.title, 'write spec');
  assert.equal(task.status, 'todo');
  assert.ok(task.updated_at);

  await t.call('POST', '/api/tasks', { body: { title: 'second' } });
  res = await t.call('GET', '/api/tasks', { auth: false });
  assert.equal((await res.json()).length, 2);

  res = await t.call('PATCH', `/api/tasks/${task.id}`, { body: { status: 'doing' } });
  assert.equal(res.status, 200);
  assert.equal((await res.json()).status, 'doing');
  res = await t.call('PATCH', `/api/tasks/${task.id}`, { body: { title: 'renamed' } });
  assert.equal((await res.json()).title, 'renamed');

  res = await t.call('GET', '/api/tasks?status=doing', { auth: false });
  const doing = await res.json();
  assert.equal(doing.length, 1);
  assert.equal(doing[0].title, 'renamed');

  res = await t.call('DELETE', `/api/tasks/${task.id}`);
  assert.equal(res.status, 204);
  res = await t.call('GET', '/api/tasks', { auth: false });
  assert.equal((await res.json()).length, 1);
  await t.close();
});

test('validation: title and status', async () => {
  const t = await boot();
  for (const body of [{ title: '   ' }, { title: 'x'.repeat(121) }, { title: 5 }, {}]) {
    assert.equal((await t.call('POST', '/api/tasks', { body })).status, 400, JSON.stringify(body).slice(0, 40));
  }
  assert.equal((await t.call('POST', '/api/tasks', { body: { title: 'x'.repeat(120) } })).status, 201);
  assert.equal((await t.call('GET', '/api/tasks?status=bogus', { auth: false })).status, 400);
  const created = await (await t.call('POST', '/api/tasks', { body: { title: 'a' } })).json();
  const p = (body) => t.call('PATCH', `/api/tasks/${created.id}`, { body });
  assert.equal((await p({ status: 'bogus' })).status, 400);
  assert.equal((await p({ title: '' })).status, 400);
  assert.equal((await p({})).status, 400);
  assert.equal((await t.call('POST', '/api/tasks', { raw: '{not json' })).status, 400);
  await t.close();
});

test('unknown id is 404, non-numeric id is 404', async () => {
  const t = await boot();
  assert.equal((await t.call('PATCH', '/api/tasks/999', { body: { status: 'done' } })).status, 404);
  assert.equal((await t.call('DELETE', '/api/tasks/999')).status, 404);
  assert.equal((await t.call('DELETE', '/api/tasks/abc')).status, 404);
  assert.equal((await t.call('GET', '/api/nope', { auth: false })).status, 404);
  await t.close();
});

test('writes need the bearer token; reads do not', async () => {
  const t = await boot();
  assert.equal((await t.call('POST', '/api/tasks', { auth: false, body: { title: 'a' } })).status, 401);
  const wrong = await fetch(`${t.base}/api/tasks`, {
    method: 'POST',
    headers: { authorization: 'Bearer wrong-token' },
    body: '{"title":"a"}',
  });
  assert.equal(wrong.status, 401);
  assert.equal((await t.call('PATCH', '/api/tasks/1', { auth: false, body: { status: 'done' } })).status, 401);
  assert.equal((await t.call('DELETE', '/api/tasks/1', { auth: false })).status, 401);
  assert.equal((await t.call('GET', '/api/tasks', { auth: false })).status, 200);
  await t.close();
});

test('method not allowed', async () => {
  const t = await boot();
  assert.equal((await t.call('PUT', '/api/tasks')).status, 405);
  assert.equal((await t.call('GET', '/api/tasks/1', { auth: false })).status, 405);
  assert.equal((await t.call('POST', '/nowhere')).status, 405);
  await t.close();
});

test('oversized body is 413', async () => {
  const t = await boot();
  const url = new URL(t.base);
  const status = await new Promise((resolve) => {
    const req = http.request(
      { host: url.hostname, port: url.port, method: 'POST', path: '/api/tasks', headers: { authorization: `Bearer ${t.TOKEN}` } },
      (res) => { res.resume(); resolve(res.statusCode); },
    );
    req.on('error', () => resolve('reset'));
    req.end('x'.repeat(70 * 1024));
  });
  assert.ok(status === 413 || status === 'reset', String(status));
  await t.close();
});

test('an internal error is a 500 with no detail', async () => {
  const db = openDb(':memory:');
  const logs = [];
  const server = createServer({ db: { list() { throw new Error('boom'); } }, token: 't', log: (e) => logs.push(e) });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const res = await fetch(`http://127.0.0.1:${server.address().port}/api/tasks`);
  assert.equal(res.status, 500);
  assert.deepEqual(await res.json(), { error: 'internal error' });
  assert.equal(logs[0].status, 500);
  server.closeAllConnections();
  await new Promise((r) => server.close(r));
  db.close();
});

test('createServer refuses an empty token; helpers', () => {
  assert.throws(() => createServer({ db: {}, token: '' }), /TASKPAD_TOKEN/);
  assert.equal(validateTitle(' ok ').value, 'ok');
  assert.ok(validateTitle(7).error);
  assert.equal(tokenOk('Bearer abc', 'abc'), true);
  assert.equal(tokenOk('Bearer abd', 'abc'), false);
  assert.equal(tokenOk(undefined, 'abc'), false);
});
