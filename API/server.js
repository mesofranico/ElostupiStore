const express = require('express');
const cors = require('cors');
const productsRouter = require('./products');
const pendingOrdersRouter = require('./pending_orders');
const membersRouter = require('./members');
const paymentsRouter = require('./payments');
const electricityReadingsRouter = require('./electricity_readings');
const electricitySettingsRouter = require('./electricity_settings');
const categoriesRouter = require('./categories');
const girasRouter = require('./giras');

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Configurar headers para UTF-8
app.use((req, res, next) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  next();
});

app.use('/api/products', productsRouter);
app.use('/api/pending-orders', pendingOrdersRouter);
app.use('/api/members', membersRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api', electricityReadingsRouter);
app.use('/api', electricitySettingsRouter);
app.use('/api/categories', categoriesRouter);
app.use('/api/giras', girasRouter);

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`API ElosTupi rodando em http://localhost:${PORT}/api/products`);
  console.log(`API de Membros: http://localhost:${PORT}/api/members`);
  console.log(`API de Pagamentos: http://localhost:${PORT}/api/payments`);
  console.log(`API de Giras: http://localhost:${PORT}/api/giras`);
}); 