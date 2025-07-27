const express = require('express');
const cors = require('cors');
const productsRouter = require('./products');
const pendingOrdersRouter = require('./pending_orders');
const membersRouter = require('./members');
const paymentsRouter = require('./payments');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/products', productsRouter);
app.use('/api/pending-orders', pendingOrdersRouter);
app.use('/api/members', membersRouter);
app.use('/api/payments', paymentsRouter);

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`API ElosTupi rodando em http://localhost:${PORT}/api/products`);
  console.log(`API de Membros: http://localhost:${PORT}/api/members`);
  console.log(`API de Pagamentos: http://localhost:${PORT}/api/payments`);
}); 