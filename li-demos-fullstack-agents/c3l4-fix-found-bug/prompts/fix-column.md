The browser agent reported that a task moved to Done appears under Doing, although the API returns status "done".
First write a failing test in test/board.test.js that reproduces it with one "doing" task and one "done" task. Run it and show it red.
Then fix groupByStatus in public/board.js with the smallest change. Run `make ci` and paste the result.
