const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

const webRoot = path.join(__dirname, 'build', 'web');

app.use(express.static(webRoot, { index: false }));

app.get('*', (req, res) => {
  res.sendFile(path.join(webRoot, 'index.html'));
});

app.listen(port, () => {
  console.log(`QuickMart Flutter app is running on port ${port}`);
});
