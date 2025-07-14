const express = require('express');
const cors = require('cors');
const productsRouter = require('./products');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/products', productsRouter);

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`API ElosTupi rodando em http://localhost:${PORT}/api/products`);
}); 