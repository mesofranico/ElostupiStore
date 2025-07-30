const express = require('express');
const router = express.Router();
const db = require('./db');

// Listar todos os pedidos pendentes
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM pending_orders ORDER BY createdAt DESC');
    // Parse items JSON
    const pedidos = rows.map(row => ({
      ...row,
      items: JSON.parse(row.items)
    }));
    res.json(pedidos);
  } catch (error) {
    console.error('Erro ao listar pendentes:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Criar novo pedido pendente
router.post('/', async (req, res) => {
  try {
    const { id, createdAt, items, total, note } = req.body;
    if (!id || !createdAt || !items || !total || !note || note.trim() === '') {
      return res.status(400).json({ error: 'Campos obrigatórios ausentes. A nota é obrigatória.' });
    }
    await db.execute(
      'INSERT INTO pending_orders (id, createdAt, items, total, note) VALUES (?, ?, ?, ?, ?)',
      [id, createdAt, JSON.stringify(items), total, note.trim()]
    );
    res.status(201).json({ success: true, message: 'Pedido pendente criado' });
  } catch (error) {
    console.error('Erro ao criar pendente:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Remover pedido pendente
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.execute('DELETE FROM pending_orders WHERE id = ?', [id]);
    res.json({ success: true, message: 'Pedido pendente removido' });
  } catch (error) {
    console.error('Erro ao remover pendente:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Finalizar pedido pendente (baixa no stock e remove)
router.post('/:id/finalize', async (req, res) => {
  const conn = await db.getConnection();
  try {
    const { id } = req.params;
    // Buscar pedido
    const [rows] = await conn.execute('SELECT * FROM pending_orders WHERE id = ?', [id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Pedido não encontrado' });
    const pedido = rows[0];
    const items = JSON.parse(pedido.items);
    // Baixar stock de cada produto
    for (const item of items) {
      const prodId = item.product.id;
      const qty = item.quantity;
      // Verificar stock atual
      const [prodRows] = await conn.execute('SELECT stock FROM products WHERE id = ?', [prodId]);
      if (prodRows.length === 0) return res.status(404).json({ error: `Produto ${prodId} não encontrado` });
      const currentStock = prodRows[0].stock;
      if (currentStock < qty) return res.status(400).json({ error: `Stock insuficiente para o produto ${prodId}` });
      await conn.execute('UPDATE products SET stock = stock - ? WHERE id = ?', [qty, prodId]);
    }
    // Remover pedido pendente
    await conn.execute('DELETE FROM pending_orders WHERE id = ?', [id]);
    res.json({ success: true, message: 'Pedido finalizado e stock atualizado' });
  } catch (error) {
    console.error('Erro ao finalizar pendente:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  } finally {
    conn.release();
  }
});

module.exports = router; 