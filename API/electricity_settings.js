const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/electricity-settings - Buscar configurações
router.get('/electricity-settings', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        default_price_per_kw,
        vat_rate,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM electricity_settings 
      ORDER BY id DESC LIMIT 1
    `);
    
    if (rows.length === 0) {
      // Se não existir configuração, criar uma padrão
      const [result] = await pool.execute(
        'INSERT INTO electricity_settings (default_price_per_kw, vat_rate) VALUES (?, ?)',
        [0.2200, 23.00]
      );
      
      const [newSettings] = await pool.execute(`
        SELECT 
          id,
          default_price_per_kw,
          vat_rate,
          CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
          CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
        FROM electricity_settings WHERE id = ?
      `, [result.insertId]);
      
      return res.json(newSettings[0]);
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar configurações:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/electricity-settings - Atualizar configurações
router.put('/electricity-settings', async (req, res) => {
  try {
    const { default_price_per_kw, vat_rate } = req.body;
    
    // Verificar se já existe configuração
    const [existing] = await pool.execute(
      'SELECT id FROM electricity_settings ORDER BY id DESC LIMIT 1'
    );
    
    if (existing.length > 0) {
      // Atualizar configuração existente
      await pool.execute(
        'UPDATE electricity_settings SET default_price_per_kw = ?, vat_rate = ?, updated_at = NOW() WHERE id = ?',
        [default_price_per_kw, vat_rate, existing[0].id]
      );
      
      const [updated] = await pool.execute(`
        SELECT 
          id,
          default_price_per_kw,
          vat_rate,
          CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
          CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
        FROM electricity_settings WHERE id = ?
      `, [existing[0].id]);
      
      res.json(updated[0]);
    } else {
      // Criar nova configuração
      const [result] = await pool.execute(
        'INSERT INTO electricity_settings (default_price_per_kw, vat_rate) VALUES (?, ?)',
        [default_price_per_kw, vat_rate]
      );
      
      const [newSettings] = await pool.execute(`
        SELECT 
          id,
          default_price_per_kw,
          vat_rate,
          CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
          CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
        FROM electricity_settings WHERE id = ?
      `, [result.insertId]);
      
      res.json(newSettings[0]);
    }
  } catch (error) {
    console.error('Erro ao atualizar configurações:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 