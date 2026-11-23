'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const Board = require('../public/board.js');

test('validateTitle trims and bounds the title', () => {
  assert.deepEqual(Board.validateTitle('  hi  '), { value: 'hi' });
  assert.ok(Board.validateTitle('   ').error);
  assert.ok(Board.validateTitle('x'.repeat(121)).error);
  assert.deepEqual(Board.validateTitle('x'.repeat(120)), { value: 'x'.repeat(120) });
});

test('groupByStatus puts every task in its own column', () => {
  const tasks = [
    { id: 1, status: 'todo' },
    { id: 2, status: 'doing' },
    { id: 3, status: 'done' },
    { id: 4, status: 'done' },
  ];
  const g = Board.groupByStatus(tasks);
  assert.deepEqual(g.todo.map((t) => t.id), [1]);
  assert.deepEqual(g.doing.map((t) => t.id), [2]);
  assert.deepEqual(g.done.map((t) => t.id), [3, 4]);
});

test('neighbour moves left and right and stops at the edges', () => {
  assert.equal(Board.neighbour('todo', 1), 'doing');
  assert.equal(Board.neighbour('doing', 1), 'done');
  assert.equal(Board.neighbour('done', -1), 'doing');
  assert.equal(Board.neighbour('todo', -1), undefined);
  assert.equal(Board.neighbour('done', 1), undefined);
});
