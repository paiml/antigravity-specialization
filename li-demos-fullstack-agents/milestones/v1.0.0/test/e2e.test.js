'use strict';
// End-to-end: a real server on localhost, a real database, and the real page script driven through a fake DOM.
// Every route and every control of the page is exercised and the result is read back from the API.
// This does NOT run a real browser: see DEMO-STATUS.md.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { boot } = require('../testlib/harness');
const { makeDocument, makeStorage, buttons, cardTitles } = require('../testlib/fakedom');
const { start } = require('../public/app.js');
const Board = require('../public/board.js');

test('static files are served with the right types', async () => {
  const t = await boot();
  for (const [p, type] of [['/', 'text/html'], ['/index.html', 'text/html'], ['/app.js', 'text/javascript'], ['/board.js', 'text/javascript'], ['/style.css', 'text/css']]) {
    const res = await fetch(t.base + p);
    assert.equal(res.status, 200, p);
    assert.match(res.headers.get('content-type'), new RegExp(type), p);
  }
  assert.equal((await fetch(`${t.base}/missing.js`)).status, 404);
  assert.equal((await fetch(`${t.base}/..%2fserver.js`)).status, 404);
  assert.equal((await fetch(`${t.base}/db.js`)).status, 404);
  await t.close();
});

test('every id the page script uses exists in index.html', () => {
  const html = fs.readFileSync(path.join(__dirname, '..', 'public', 'index.html'), 'utf8');
  for (const id of ['message', 'token', 'title', 'task-form', 'col-todo', 'col-doing', 'col-done', 'count-todo', 'count-doing', 'count-done']) {
    assert.ok(html.includes(`id="${id}"`), id);
  }
});

test('the page: add, move both ways, delete, validation, token handling', async () => {
  const t = await boot();
  const doc = makeDocument();
  const storage = makeStorage({ 'taskpad-token': 'stored' });
  const base = (u, o) => fetch(t.base + u, o);
  await start({ document: doc, fetch: base, storage, Board });
  const { els } = doc;
  assert.equal(els.token.value, 'stored');
  els.token.value = t.TOKEN;
  els.token.fire('input');
  assert.equal(storage.getItem('taskpad-token'), t.TOKEN);

  // validation happens in the page, before any request
  els.title.value = '   ';
  await els['task-form'].fire('submit');
  assert.equal(els.message.textContent, 'Enter a title.');
  els.title.value = 'x'.repeat(121);
  await els['task-form'].fire('submit');
  assert.match(els.message.textContent, /longer than 120/);
  assert.equal((await (await t.call('GET', '/api/tasks')).json()).length, 0);

  // add
  els.title.value = '  Buy milk ';
  await els['task-form'].fire('submit');
  assert.equal(els.message.textContent, '');
  assert.equal(els.title.value, '');
  assert.deepEqual(cardTitles(els['col-todo']), ['Buy milk']);
  assert.equal(els['count-todo'].textContent, '1');

  // move right twice: todo -> doing -> done; the card has move-right and delete only at the left edge
  const card = () => els['col-todo'].children[0] || els['col-doing'].children[0] || els['col-done'].children[0];
  assert.equal(buttons(card()).length, 2);
  await buttons(card())[0].fire('click');
  assert.deepEqual(cardTitles(els['col-doing']), ['Buy milk']);
  assert.equal(buttons(card()).length, 3);
  await buttons(card())[1].fire('click');
  assert.deepEqual(cardTitles(els['col-done']), ['Buy milk']);
  assert.equal((await (await t.call('GET', '/api/tasks?status=done')).json()).length, 1);
  // move left from done
  await buttons(card())[0].fire('click');
  assert.deepEqual(cardTitles(els['col-doing']), ['Buy milk']);
  assert.match(buttons(card())[0].attrs['aria-label'], /Move "Buy milk" to To do/);

  // a wrong token is reported, nothing changes
  els.token.value = 'wrong';
  await buttons(card())[0].fire('click');
  assert.equal(els.message.textContent, 'Not authorised: check the token.');
  assert.deepEqual(cardTitles(els['col-doing']), ['Buy milk']);

  // a server-side error message is shown (task deleted behind the page's back)
  els.token.value = t.TOKEN;
  const id = (await (await t.call('GET', '/api/tasks')).json())[0].id;
  const stale = buttons(card())[0];
  await t.call('DELETE', `/api/tasks/${id}`);
  await stale.fire('click');
  assert.equal(els.message.textContent, 'no such task');

  // delete from the page
  await t.call('POST', '/api/tasks', { body: { title: 'to delete' } });
  await start({ document: doc, fetch: base, storage, Board });
  const del = buttons(card()).find((b) => b.textContent === 'Delete');
  await del.fire('click');
  assert.equal((await (await t.call('GET', '/api/tasks')).json()).length, 0);
  assert.deepEqual(cardTitles(els['col-todo']), []);
  await t.close();
});

test('an error body without a message falls back to a generic line', async () => {
  const doc = makeDocument();
  const fake = async () => ({ ok: false, status: 500, json: async () => ({}), });
  await start({ document: doc, fetch: async (u) => (u === '/api/tasks' ? { json: async () => [] } : fake()), storage: makeStorage(), Board });
  doc.els.title.value = 'a';
  await doc.els['task-form'].fire('submit');
  assert.equal(doc.els.message.textContent, 'Request failed.');
  assert.equal(doc.els.title.value, 'a');
});
