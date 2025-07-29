const express = require('express');
const router = express.Router();
const pool = require('./db');

// Buscar todas as leituras (ordenadas por data decrescente)
router.get('/electricity-readings', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        counter_value,
        kw_consumed,
        price_per_kw,
        total_cost,
        CONVERT_TZ(reading_date, '+00:00', '+01:00') as reading_date,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM electricity_readings 
      ORDER BY reading_date DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar leituras:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Adicionar nova leitura
router.post('/electricity-readings', async (req, res) => {
  try {
    const { counter_value, kw_consumed, price_per_kw, total_cost, notes } = req.body;
    
    const [result] = await pool.execute(
      'INSERT INTO electricity_readings (counter_value, kw_consumed, price_per_kw, total_cost, reading_date, notes) VALUES (?, ?, ?, ?, NOW(), ?)',
      [counter_value, kw_consumed, price_per_kw, total_cost, notes || '']
    );
    
    // Buscar a leitura recém-criada
    const [rows] = await pool.execute(`
      SELECT 
        id,
        counter_value,
        kw_consumed,
        price_per_kw,
        total_cost,
        CONVERT_TZ(reading_date, '+00:00', '+01:00') as reading_date,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM electricity_readings WHERE id = ?
    `, [result.insertId]);
    
    res.status(201).json(rows[0]);
  } catch (error) {
    console.error('Erro ao adicionar leitura:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Atualizar leitura existente
router.put('/electricity-readings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { counter_value, kw_consumed, price_per_kw, total_cost, notes } = req.body;
    
    await pool.execute(
      'UPDATE electricity_readings SET counter_value = ?, kw_consumed = ?, price_per_kw = ?, total_cost = ?, notes = ? WHERE id = ?',
      [counter_value, kw_consumed, price_per_kw, total_cost, notes || '', id]
    );
    
    // Buscar a leitura atualizada
    const [rows] = await pool.execute(`
      SELECT 
        id,
        counter_value,
        kw_consumed,
        price_per_kw,
        total_cost,
        CONVERT_TZ(reading_date, '+00:00', '+01:00') as reading_date,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM electricity_readings WHERE id = ?
    `, [id]);
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao atualizar leitura:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Excluir leitura
router.delete('/electricity-readings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    await pool.execute(
      'DELETE FROM electricity_readings WHERE id = ?',
      [id]
    );
    
    res.status(200).json({ message: 'Leitura excluída com sucesso' });
  } catch (error) {
    console.error('Erro ao excluir leitura:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// Buscar leitura por ID
router.get('/electricity-readings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.execute(`
      SELECT 
        id,
        counter_value,
        kw_consumed,
        price_per_kw,
        total_cost,
        CONVERT_TZ(reading_date, '+00:00', '+01:00') as reading_date,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM electricity_readings WHERE id = ?
    `, [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Leitura não encontrada' });
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar leitura:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 