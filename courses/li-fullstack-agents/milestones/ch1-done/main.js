'use strict';
const { createServer } = require('./server');

const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '127.0.0.1';
createServer({ log: (e) => console.error(JSON.stringify(e)) }).listen(port, host, () => {
  console.log(`taskpad listening on http://${host}:${port}`);
});
