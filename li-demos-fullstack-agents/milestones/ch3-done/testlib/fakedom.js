'use strict';
// A tiny fake DOM, just enough for public/app.js. It records what the page would show.
class FakeEl {
  constructor(tag = 'div') {
    this.tag = tag;
    this.children = [];
    this.attrs = {};
    this.listeners = {};
    this.textContent = '';
    this.value = '';
  }
  setAttribute(k, v) { this.attrs[k] = v; }
  append(...kids) { this.children.push(...kids); }
  replaceChildren(...kids) { this.children = kids; }
  addEventListener(type, fn) { this.listeners[type] = fn; }
  fire(type, ev = {}) { return this.listeners[type]({ preventDefault() {}, ...ev }); }
  find(pred, out = []) { if (pred(this)) out.push(this); this.children.forEach((c) => c.find(pred, out)); return out; }
}

const IDS = ['message', 'token', 'title', 'task-form', 'col-todo', 'col-doing', 'col-done', 'count-todo', 'count-doing', 'count-done'];

function makeDocument() {
  const els = Object.fromEntries(IDS.map((id) => [id, new FakeEl()]));
  return { els, getElementById: (id) => els[id], createElement: (t) => new FakeEl(t) };
}

function makeStorage(initial = {}) {
  const m = new Map(Object.entries(initial));
  return { getItem: (k) => (m.has(k) ? m.get(k) : null), setItem: (k, v) => m.set(k, v), map: m };
}

const buttons = (el) => el.find((e) => e.tag === 'button');
const cardTitles = (col) => col.children.map((li) => li.children[0].textContent);

module.exports = { makeDocument, makeStorage, buttons, cardTitles };
