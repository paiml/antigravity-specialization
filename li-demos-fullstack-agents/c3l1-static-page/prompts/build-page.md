Build the page for Taskpad in public/: index.html, style.css, board.js (pure logic: title check, grouping by status, neighbour column) and app.js.
Rules from CONTEXT.md apply: no framework, no innerHTML, build nodes and set textContent. The page has a labelled add form with a title field and a
password-type token field kept in sessionStorage, three columns with counts, and move and delete buttons on every card with an aria-label.
Write the tests first: test/board.test.js for the logic and test/e2e.test.js that runs app.js against the real server with a fake DOM.
Run `make ci` and paste the result.
