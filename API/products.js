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
      'INSERT INTO products (id, name, price, price2, description, imageUrl, category, stock) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [id, name, price, price2 || null, description || '', imageUrl || '', category || '', stock || 0]
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
      'UPDATE products SET name = ?, price = ?, price2 = ?, description = ?, imageUrl = ?, category = ?, stock = ? WHERE id = ?',
      [name, price, price2 || null, description || '', imageUrl || '', category || '', stock || 0, id]
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
    const { quantity } = req.body;
    if (!quantity || quantity <= 0) return res.status(400).json({ error: 'Quantidade inválida' });

    const [product] = await db.execute('SELECT stock FROM products WHERE id = ?', [id]);
    if (product.length === 0) return res.status(404).json({ error: 'Produto não encontrado' });

    const currentStock = product[0].stock;
    if (currentStock < quantity) return res.status(400).json({ error: 'Stock insuficiente' });

    await db.execute('UPDATE products SET stock = stock - ? WHERE id = ?', [quantity, id]);
    res.json({ success: true, newStock: currentStock - quantity });
  } catch (error) {
    console.error('Erro ao decrementar stock:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 