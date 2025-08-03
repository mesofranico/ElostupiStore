const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/categories/order - Buscar ordem das categorias
router.get('/order', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        category_name,
        position,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM category_order 
      ORDER BY position ASC
    `);
    
    // Extrair apenas os nomes das categorias na ordem correta
    const orderedCategories = rows.map(row => row.category_name);
    
    res.json(orderedCategories);
  } catch (error) {
    console.error('Erro ao buscar ordem das categorias:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/categories/order - Atualizar ordem das categorias
router.post('/order', async (req, res) => {
  try {
    const { categories } = req.body;
    
    if (!Array.isArray(categories)) {
      return res.status(400).json({ error: 'Categorias devem ser um array' });
    }
    
    // Iniciar transação
    await pool.execute('START TRANSACTION');
    
    try {
      // Limpar ordem atual
      await pool.execute('DELETE FROM category_order');
      
      // Inserir nova ordem
      for (let i = 0; i < categories.length; i++) {
        await pool.execute(
          'INSERT INTO category_order (category_name, position) VALUES (?, ?)',
          [categories[i], i + 1]
        );
      }
      
      // Confirmar transação
      await pool.execute('COMMIT');
      
      res.json({ 
        message: 'Ordem das categorias atualizada com sucesso',
        categories: categories
      });
      
    } catch (transactionError) {
      // Reverter transação em caso de erro
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao atualizar ordem das categorias:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/categories/sync - Sincronizar categorias com produtos existentes
router.post('/sync', async (req, res) => {
  try {
    // Buscar todas as categorias únicas dos produtos
    const [productCategories] = await pool.execute(`
      SELECT DISTINCT category 
      FROM products 
      WHERE category IS NOT NULL AND category != ''
      ORDER BY category ASC
    `);
    
    const categories = productCategories.map(row => row.category);
    
    // Buscar ordem atual
    const [currentOrder] = await pool.execute(`
      SELECT category_name, position 
      FROM category_order 
      ORDER BY position ASC
    `);
    
    const currentOrderedCategories = currentOrder.map(row => row.category_name);
    
    // Combinar: manter ordem atual + adicionar novas categorias
    const finalOrder = [...currentOrderedCategories];
    
    // Adicionar categorias que não estão na ordem atual
    for (const category of categories) {
      if (!finalOrder.includes(category)) {
        finalOrder.push(category);
      }
    }
    
    // Atualizar ordem na base de dados
    await pool.execute('START TRANSACTION');
    
    try {
      // Limpar ordem atual
      await pool.execute('DELETE FROM category_order');
      
      // Inserir ordem final
      for (let i = 0; i < finalOrder.length; i++) {
        await pool.execute(
          'INSERT INTO category_order (category_name, position) VALUES (?, ?)',
          [finalOrder[i], i + 1]
        );
      }
      
      await pool.execute('COMMIT');
      
      res.json({ 
        message: 'Categorias sincronizadas com sucesso',
        categories: finalOrder,
        added: finalOrder.filter(cat => !currentOrderedCategories.includes(cat))
      });
      
    } catch (transactionError) {
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao sincronizar categorias:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 