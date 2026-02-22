const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/finance - Listar registos financeiros com filtros
router.get('/', async (req, res) => {
    try {
        const { start, end, type } = req.query;
        let query = 'SELECT * FROM financial_records WHERE 1=1';
        const params = [];

        if (start && end) {
            query += ' AND record_date BETWEEN ? AND ?';
            params.push(start, end);
        }

        if (type) {
            query += ' AND type = ?';
            params.push(type);
        }

        query += ' ORDER BY record_date DESC, created_at DESC';

        const [rows] = await pool.execute(query, params);
        res.json(rows);
    } catch (error) {
        console.error('Erro ao buscar registos financeiros:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// POST /api/finance - Criar novo registo (Entrada/Saída)
router.post('/', async (req, res) => {
    try {
        const { type, category, amount, description, record_date } = req.body;

        if (!type || !category || !amount || !record_date) {
            return res.status(400).json({ error: 'Campos obrigatórios em falta' });
        }

        const [result] = await pool.execute(
            'INSERT INTO financial_records (type, category, amount, description, record_date) VALUES (?, ?, ?, ?, ?)',
            [type, category, amount, description || null, record_date]
        );

        const [newRecord] = await pool.execute('SELECT * FROM financial_records WHERE id = ?', [result.insertId]);
        res.status(201).json(newRecord[0]);
    } catch (error) {
        console.error('Erro ao criar registo financeiro:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// DELETE /api/finance/:id - Deletar registo
router.delete('/:id', async (req, res) => {
    try {
        const [result] = await pool.execute('DELETE FROM financial_records WHERE id = ?', [req.params.id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Registo não encontrado' });
        }

        res.json({ message: 'Registo deletado com sucesso' });
    } catch (error) {
        console.error('Erro ao deletar registo financeiro:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// GET /api/finance/report - Relatório consolidado (Baseado exclusivamente em financial_records)
router.get('/report', async (req, res) => {
    try {
        const { start, end } = req.query;

        if (!start || !end) {
            return res.status(400).json({ error: 'Período (start/end) é obrigatório' });
        }

        // 1. Somar mensalidades automáticas
        const [membershipSum] = await pool.execute(
            "SELECT SUM(amount) as total FROM financial_records WHERE type = 'income' AND category = 'Mensalidade' AND record_date BETWEEN ? AND ?",
            [start, end]
        );

        // 2. Somar vendas de produtos automáticas
        const [salesSum] = await pool.execute(
            "SELECT SUM(amount) as total FROM financial_records WHERE type = 'income' AND category = 'Venda de Produtos' AND record_date BETWEEN ? AND ?",
            [start, end]
        );

        // 3. Somar outros rendimentos (manuais)
        const [otherIncomeSum] = await pool.execute(
            "SELECT SUM(amount) as total FROM financial_records WHERE type = 'income' AND category NOT IN ('Mensalidade', 'Venda de Produtos') AND record_date BETWEEN ? AND ?",
            [start, end]
        );

        // 4. Somar gastos/despesas
        const [expensesSum] = await pool.execute(
            "SELECT SUM(amount) as total FROM financial_records WHERE type = 'expense' AND record_date BETWEEN ? AND ?",
            [start, end]
        );

        const membership = parseFloat(membershipSum[0].total || 0);
        const sales = parseFloat(salesSum[0].total || 0);
        const otherIncome = parseFloat(otherIncomeSum[0].total || 0);
        const totalExpenses = parseFloat(expensesSum[0].total || 0);
        const totalIncome = membership + sales + otherIncome;

        res.json({
            period: { start, end },
            income: {
                membership: membership,
                sales: sales,
                other: otherIncome,
                total: totalIncome
            },
            expense: {
                total: totalExpenses
            },
            balance: totalIncome - totalExpenses
        });
    } catch (error) {
        console.error('Erro ao gerar relatório financeiro:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

module.exports = router;
