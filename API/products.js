const express = require('express');
const router = express.Router();
const db = require('./db');

// Listar todos os produtos
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM products ORDER BY category, name');
    res.json(rows);
  } catch (error) {
    console.error('Erro ao listar produtos:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Buscar produto por id
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await db.execute('SELECT * FROM products WHERE id = ?', [id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Produto não encontrado' });
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar produto:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Criar novo produto
router.post('/', async (req, res) => {
  try {
    const { id, name, price, price2, description, imageUrl, category, stock } = req.body;

    // Validações básicas
    if (!id || !name || !price) {
      return res.status(400).json({ error: 'ID, nome e preço são obrigatórios' });
    }

    // Verificar se o produto já existe
    const [existing] = await db.execute('SELECT id FROM products WHERE id = ?', [id]);
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Produto com este ID já existe' });
    }

    // Inserir novo produto
    await db.execute(
      'INSERT INTO products (id, name, price, price2, description, imageUrl, category, stock, manage_stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, name, price, price2 || null, description || '', imageUrl || '', category || '', stock || 0, req.body.manage_stock === undefined ? 1 : (req.body.manage_stock ? 1 : 0)]
    );

    res.status(201).json({ success: true, message: 'Produto criado com sucesso' });
  } catch (error) {
    console.error('Erro ao criar produto:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Atualizar produto
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, price, price2, description, imageUrl, category, stock } = req.body;

    // Verificar se o produto existe
    const [existing] = await db.execute('SELECT id FROM products WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Produto não encontrado' });
    }

    // Atualizar produto
    await db.execute(
      'UPDATE products SET name = ?, price = ?, price2 = ?, description = ?, imageUrl = ?, category = ?, stock = ?, manage_stock = ? WHERE id = ?',
      [name, price, price2 || null, description || '', imageUrl || '', category || '', stock || 0, req.body.manage_stock === undefined ? 1 : (req.body.manage_stock ? 1 : 0), id]
    );

    res.json({ success: true, message: 'Produto atualizado com sucesso' });
  } catch (error) {
    console.error('Erro ao atualizar produto:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Deletar produto
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Verificar se o produto existe
    const [existing] = await db.execute('SELECT id FROM products WHERE id = ?', [id]);
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Produto não encontrado' });
    }

    // Deletar produto
    await db.execute('DELETE FROM products WHERE id = ?', [id]);

    res.json({ success: true, message: 'Produto deletado com sucesso' });
  } catch (error) {
    console.error('Erro ao deletar produto:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Dar baixa no stock
router.post('/:id/decrement', async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity, isInternal } = req.body;
    if (!quantity || quantity <= 0) return res.status(400).json({ error: 'Quantidade inválida' });

    const [product] = await db.execute('SELECT stock, manage_stock FROM products WHERE id = ?', [id]);
    if (product.length === 0) return res.status(404).json({ error: 'Produto não encontrado' });

    const currentStock = product[0].stock;
    const manageStock = product[0].manage_stock;

    if (manageStock && currentStock < quantity) return res.status(400).json({ error: 'Stock insuficiente' });

    if (manageStock) {
      await db.execute('UPDATE products SET stock = stock - ? WHERE id = ?', [quantity, id]);
    }

    // Registar nos relatórios financeiros
    const [prodData] = await db.execute('SELECT name, price FROM products WHERE id = ?', [id]);
    const amount = prodData[0].price * quantity;
    const recordDate = new Date().toISOString().split('T')[0];

    const details = JSON.stringify({
      items: [{ name: prodData[0].name, quantity: quantity, price: prodData[0].price }]
    });

    if (isInternal) {
      await db.execute(
        "INSERT INTO financial_records (type, category, amount, description, record_date, details) VALUES ('expense', 'Consumo Interno', ?, ?, ?, ?)",
        [amount, `Consumo Interno: ${quantity}x ${prodData[0].name}`, recordDate, details]
      );
    } else {
      await db.execute(
        "INSERT INTO financial_records (type, category, amount, description, record_date, details) VALUES ('income', 'Venda de Produtos', ?, ?, ?, ?)",
        [amount, `Venda direta de ${quantity}x ${prodData[0].name}`, recordDate, details]
      );
    }

    res.json({ success: true, newStock: currentStock - quantity });
  } catch (error) {
    console.error('Erro ao decrementar stock:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/products/bulk-decrement - Decrementar stock de múltiplos produtos (Venda Consolidada)
router.post('/bulk-decrement', async (req, res) => {
  const conn = await db.getConnection();
  try {
    const { items, isInternal } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Lista de produtos inválida' });
    }

    await conn.beginTransaction();

    let totalAmount = 0;
    const detailItems = [];
    const recordDate = new Date().toISOString().split('T')[0];

    for (const item of items) {
      const { id, quantity } = item;

      // 1. Verificar stock e configuração
      const [prodRows] = await conn.execute(
        'SELECT name, price, stock, manage_stock FROM products WHERE id = ?',
        [id]
      );

      if (prodRows.length === 0) {
        throw new Error(`Produto ${id} não encontrado`);
      }

      const product = prodRows[0];
      const currentStock = product.stock;
      const manageStock = product.manage_stock;

      if (manageStock && currentStock < quantity) {
        throw new Error(`Stock insuficiente para o produto ${product.name}`);
      }

      // 2. Decrementar stock se gerido
      if (manageStock) {
        await conn.execute(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [quantity, id]
        );
      }

      // 3. Acumular valores para o registo financeiro único
      totalAmount += product.price * quantity;
      detailItems.push({
        name: product.name,
        quantity: quantity,
        price: product.price
      });
    }

    // 4. Criar registo financeiro único para a venda total
    const details = JSON.stringify({ items: detailItems });
    const description = isInternal
      ? `Venda Consolidada (Consumo Interno): ${items.length} itens`
      : `Venda Consolidada: ${items.length} itens`;
    const category = isInternal ? 'Consumo Interno' : 'Venda de Produtos';
    const type = isInternal ? 'expense' : 'income';

    await conn.execute(
      "INSERT INTO financial_records (type, category, amount, description, record_date, details) VALUES (?, ?, ?, ?, ?, ?)",
      [type, category, totalAmount, description, recordDate, details]
    );

    await conn.commit();
    res.json({ success: true, message: 'Venda consolidada processada com sucesso' });
  } catch (error) {
    await conn.rollback();
    console.error('Erro no bulk-decrement:', error);
    res.status(400).json({ error: error.message || 'Erro ao processar venda consolidada' });
  } finally {
    conn.release();
  }
});

module.exports = router; 