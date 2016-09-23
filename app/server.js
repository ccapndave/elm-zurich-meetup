const path = require('path');
const express = require('express');
const liveReload = require('connect-livereload');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express()
  .use(cors())
  .use(liveReload())
  .use(bodyParser.json())
  .use(express.static(path.join(__dirname, '/../build')));

const server = app.listen(3000, () => {
  const host = server.address().address;
  const port = server.address().port;

  console.log(`Elm server listening at http://${host}:${port}`);
});
