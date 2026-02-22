const express = require('express');
const router = express.Router();
const pool = require('./db');

// POST /api/admin/reset - Reset completo do sistema (exceto membros, produtos e consulentes)
router.post('/reset', async (req, res) => {
    const { pin } = req.body;

    if (pin !== '1989') {
        return res.status(401).json({ error: 'PIN incorreto' });
    }

    const conn = await pool.getConnection();
    try {
        await conn.beginTransaction();

        console.log('Iniciando reset completo do sistema...');

        // 1. Limpar tabelas de histórico e registos
        await conn.execute('TRUNCATE TABLE payments');
        await conn.execute('TRUNCATE TABLE financial_records');
        await conn.execute('TRUNCATE TABLE attendance_records');
        await conn.execute('TRUNCATE TABLE consulente_sessions');
        await conn.execute('TRUNCATE TABLE electricity_readings');
        await conn.execute('TRUNCATE TABLE pending_orders');
        await conn.execute('TRUNCATE TABLE recados');

        console.log('Tabelas de histórico truncadas com sucesso.');

        // 2. Resetar status de pagamento e datas dos membros
        // Definir join_date e next_payment_date como 1º do mês atual
        const now = new Date();
        const currentMonthFirst = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01 00:00:00`;

        await conn.execute(`
            UPDATE members SET 
            join_date = ?,
            last_payment_date = NULL,
            payment_status = 'pending',
            next_payment_date = ?,
            updated_at = NOW()
        `, [currentMonthFirst, currentMonthFirst]);

        console.log('Status de pagamento dos membros resetados.');

        await conn.commit();
        console.log('Reset do sistema concluído com sucesso.');

        res.json({ message: 'Sistema resetado com sucesso. Histórico limpo e mensalidades reiniciadas.' });
    } catch (error) {
        await conn.rollback();
        console.error('Erro durante o reset do sistema:', error);
        res.status(500).json({ error: 'Erro interno ao resetar o sistema', details: error.message });
    } finally {
        conn.release();
    }
});

module.exports = router;
