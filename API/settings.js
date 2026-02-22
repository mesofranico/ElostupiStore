const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/settings - Obter todas as configurações
router.get('/', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT setting_key, setting_value, description FROM settings');

        // Converte array de resultados num objeto chave: valor
        const settings = {};
        rows.forEach(row => {
            settings[row.setting_key] = row.setting_value;
        });

        res.json(settings);
    } catch (error) {
        console.error('Erro ao buscar definições:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// GET /api/settings/:key - Obter uma configuração específica
router.get('/:key', async (req, res) => {
    try {
        const { key } = req.params;
        const [rows] = await pool.execute('SELECT setting_value FROM settings WHERE setting_key = ?', [key]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Configuração não encontrada' });
        }

        res.json({ value: rows[0].setting_value });
    } catch (error) {
        console.error('Erro ao buscar a configuração:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// PUT /api/settings/:key - Atualizar uma configuração específica
router.put('/:key', async (req, res) => {
    try {
        const { key } = req.params;
        const { value } = req.body;

        if (value === undefined) {
            return res.status(400).json({ error: 'O valor é obrigatório' });
        }

        // Verifica se existe
        const [existing] = await pool.execute('SELECT setting_key FROM settings WHERE setting_key = ?', [key]);

        if (existing.length === 0) {
            // Cria a configuração se não existir e não precisar de erro
            await pool.execute('INSERT INTO settings (setting_key, setting_value) VALUES (?, ?)', [key, value]);
        } else {
            // Atualiza
            await pool.execute('UPDATE settings SET setting_value = ? WHERE setting_key = ?', [value, key]);
        }

        const [updated] = await pool.execute('SELECT setting_key, setting_value FROM settings WHERE setting_key = ?', [key]);
        res.json(updated[0]);
    } catch (error) {
        console.error('Erro ao atualizar a configuração:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

module.exports = router;
