'use strict';
// Taskpad page script. start() takes its dependencies so tests can drive it with a fake DOM.
function start({ document, fetch, storage, Board }) {
  const el = (id) => document.getElementById(id);
  const message = el('message');
  const tokenField = el('token');
  const titleField = el('title');
  tokenField.value = storage.getItem('taskpad-token') || '';
  tokenField.addEventListener('input', () => storage.setItem('taskpad-token', tokenField.value));

  const headers = () => ({ 'content-type': 'application/json', authorization: `Bearer ${tokenField.value}` });

  async function failure(res) {
    if (res.status === 401) return 'Not authorised: check the token.';
    const body = await res.json();
    return body.error || 'Request failed.';
  }

  function card(task) {
    const li = document.createElement('li');
    li.setAttribute('data-id', String(task.id));
    const title = document.createElement('span');
    title.textContent = task.title;
    li.append(title);
    for (const dir of [-1, 1]) {
      const to = Board.neighbour(task.status, dir);
      if (!to) continue;
      const b = document.createElement('button');
      b.setAttribute('type', 'button');
      b.setAttribute('aria-label', `Move "${task.title}" to ${Board.LABELS[to]}`);
      b.textContent = dir < 0 ? '←' : '→';
      b.addEventListener('click', () => change(task.id, { status: to }));
      li.append(b);
    }
    const del = document.createElement('button');
    del.setAttribute('type', 'button');
    del.setAttribute('aria-label', `Delete "${task.title}"`);
    del.textContent = 'Delete';
    del.addEventListener('click', () => remove(task.id));
    li.append(del);
    return li;
  }

  function render(tasks) {
    const groups = Board.groupByStatus(tasks);
    for (const s of Board.STATUSES) {
      el(`col-${s}`).replaceChildren(...groups[s].map(card));
      el(`count-${s}`).textContent = String(groups[s].length);
    }
  }

  async function load() {
    const res = await fetch('/api/tasks');
    render(await res.json());
  }

  async function send(method, url, body) {
    const res = await fetch(url, { method, headers: headers(), body: body && JSON.stringify(body) });
    if (!res.ok) {
      message.textContent = await failure(res);
      return false;
    }
    message.textContent = '';
    await load();
    return true;
  }

  const change = (id, patch) => send('PATCH', `/api/tasks/${id}`, patch);
  const remove = (id) => send('DELETE', `/api/tasks/${id}`);

  el('task-form').addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const t = Board.validateTitle(titleField.value);
    if (t.error) {
      message.textContent = t.error;
      return;
    }
    if (await send('POST', '/api/tasks', { title: t.value })) titleField.value = '';
  });

  return load();
}

if (typeof module !== 'undefined') module.exports = { start }; else start({ document, fetch: fetch.bind(window), storage: sessionStorage, Board });
