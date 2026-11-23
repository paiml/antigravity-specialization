'use strict';
// Pure board logic. Loaded as a classic script in the page (global Board) and with require() in tests.
const Board = (() => {
  const STATUSES = ['todo', 'doing', 'done'];
  const LABELS = { todo: 'To do', doing: 'Doing', done: 'Done' };

  function validateTitle(raw) {
    const value = String(raw).trim();
    if (value.length < 1) return { error: 'Enter a title.' };
    if (value.length > 120) return { error: 'The title is longer than 120 characters.' };
    return { value };
  }

  function groupByStatus(tasks) {
    const groups = { todo: [], doing: [], done: [] };
    for (const t of tasks) groups[t.status].push(t);
    return groups;
  }

  // neighbour(status, -1 | 1): the column to the left or right, or undefined at the edge.
  function neighbour(status, dir) {
    return STATUSES[STATUSES.indexOf(status) + dir];
  }

  return { STATUSES, LABELS, validateTitle, groupByStatus, neighbour };
})();

if (typeof module !== 'undefined') module.exports = Board;
