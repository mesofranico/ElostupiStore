const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/payments - Buscar todos os pagamentos
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      ORDER BY p.payment_date DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar pagamentos:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/payments/:id - Buscar pagamento por ID
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.id = ?
    `, [req.params.id]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Pagamento não encontrado' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar pagamento:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/payments - Criar novo pagamento
router.post('/', async (req, res) => {
  try {
    const {
      member_id,
      amount,
      payment_date,
      status,
      payment_type
    } = req.body;

    console.log('Criando pagamento:', {
      member_id,
      amount,
      payment_date,
      status,
      payment_type: payment_type || 'regular'
    });

    const [result] = await pool.execute(`
      INSERT INTO payments (
        member_id, amount, payment_date, 
        status, payment_type, created_at
      ) VALUES (?, ?, ?, ?, ?, NOW())
    `, [
      member_id, amount, payment_date,
      status, payment_type || 'regular'
    ]);

    // Atualizar status do membro se o pagamento for concluído
    if (status === 'completed') {
      // Buscar informações do membro para calcular a próxima data corretamente
      const [memberRows] = await pool.execute(
        'SELECT membership_type FROM members WHERE id = ?',
        [member_id]
      );

      if (memberRows.length > 0) {
        const membershipType = memberRows[0].membership_type;

        // Calcular próxima data baseada no tipo de mensalidade
        let nextPaymentDate;
        switch (membershipType.toLowerCase()) {
          case 'mensal':
            nextPaymentDate = `DATE_ADD(?, INTERVAL 1 MONTH)`;
            break;
          case 'trimestral':
            nextPaymentDate = `DATE_ADD(?, INTERVAL 3 MONTH)`;
            break;
          case 'semestral':
            nextPaymentDate = `DATE_ADD(?, INTERVAL 6 MONTH)`;
            break;
          case 'anual':
            nextPaymentDate = `DATE_ADD(?, INTERVAL 12 MONTH)`;
            break;
          default:
            nextPaymentDate = `DATE_ADD(?, INTERVAL 1 MONTH)`;
        }

        await pool.execute(`
          UPDATE members SET 
            last_payment_date = ?,
            payment_status = 'paid',
            next_payment_date = ${nextPaymentDate}
          WHERE id = ?
        `, [payment_date, payment_date, member_id]);
      }
    }

    const [newPayment] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.id = ?
    `, [result.insertId]);

    // Registar na contabilidade central se concluído
    if (status === 'completed') {
      const p = newPayment[0];
      const details = JSON.stringify({
        memberId: p.member_id,
        memberName: p.member_name,
        paymentType: p.payment_type
      });

      // Traduzir tipo de pagamento para a descrição
      let typeLabel = p.payment_type;
      if (p.payment_type === 'regular') typeLabel = 'Mensal';
      else if (p.payment_type === 'overdue') typeLabel = 'Em Atraso';
      else if (p.payment_type === 'advance') typeLabel = 'Adiantado';

      // Formatar data de forma segura (YYYY-MM-DD)
      const dateStr = (p.payment_date instanceof Date ? p.payment_date.toISOString() : p.payment_date.toString()).split('T')[0];

      await pool.execute(
        "INSERT INTO financial_records (type, category, amount, description, record_date, details) VALUES ('income', 'Mensalidade', ?, ?, ?, ?)",
        [p.amount, `Mensalidade: ${p.member_name} (${typeLabel})`, dateStr, details]
      );
    }

    res.status(201).json(newPayment[0]);
  } catch (error) {
    console.error('Erro ao criar pagamento:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/payments/:id - Atualizar pagamento
router.put('/:id', async (req, res) => {
  try {
    const {
      member_id,
      amount,
      payment_date,
      status
    } = req.body;

    await pool.execute(`
      UPDATE payments SET 
        member_id = ?, amount = ?, payment_date = ?, 
        status = ?, updated_at = NOW()
      WHERE id = ?
    `, [
      member_id, amount, payment_date,
      status, req.params.id
    ]);

    // Atualizar status do membro se o pagamento for concluído
    if (status === 'completed') {
      // Buscar informações do membro para calcular a próxima data corretamente (igual ao POST)
      const [memberRows] = await pool.execute(
        'SELECT membership_type FROM members WHERE id = ?',
        [member_id]
      );

      if (memberRows.length > 0) {
        const membershipType = memberRows[0].membership_type;
        let nextPaymentDate;
        switch (membershipType.toLowerCase()) {
          case 'mensal': nextPaymentDate = `DATE_ADD(?, INTERVAL 1 MONTH)`; break;
          case 'trimestral': nextPaymentDate = `DATE_ADD(?, INTERVAL 3 MONTH)`; break;
          case 'semestral': nextPaymentDate = `DATE_ADD(?, INTERVAL 6 MONTH)`; break;
          case 'anual': nextPaymentDate = `DATE_ADD(?, INTERVAL 12 MONTH)`; break;
          default: nextPaymentDate = `DATE_ADD(?, INTERVAL 1 MONTH)`;
        }

        await pool.execute(`
          UPDATE members SET 
            last_payment_date = ?,
            payment_status = 'paid',
            next_payment_date = ${nextPaymentDate}
          WHERE id = ?
        `, [payment_date, payment_date, member_id]);
      }
    }

    const [updatedPayment] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.id = ?
    `, [req.params.id]);

    // Registar na contabilidade central se transição para concluído
    if (status === 'completed') {
      const p = updatedPayment[0];
      const details = JSON.stringify({
        memberId: p.member_id,
        memberName: p.member_name,
        paymentType: p.payment_type
      });

      const dateStr = (p.payment_date instanceof Date ? p.payment_date.toISOString() : p.payment_date.toString()).split('T')[0];

      await pool.execute(
        "INSERT INTO financial_records (type, category, amount, description, record_date, details) VALUES ('income', 'Mensalidade', ?, ?, ?, ?)",
        [p.amount, `Mensalidade: ${p.member_name} (${p.payment_type})`, dateStr, details]
      );
    }

    if (updatedPayment.length === 0) {
      return res.status(404).json({ error: 'Pagamento não encontrado' });
    }

    res.json(updatedPayment[0]);
  } catch (error) {
    console.error('Erro ao atualizar pagamento:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/payments/:id - Deletar pagamento
router.delete('/:id', async (req, res) => {
  try {
    const [result] = await pool.execute(
      'DELETE FROM payments WHERE id = ?',
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Pagamento não encontrado' });
    }

    res.json({ message: 'Pagamento deletado com sucesso' });
  } catch (error) {
    console.error('Erro ao deletar pagamento:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/payments/member/:memberId - Buscar pagamentos por membro
router.get('/member/:memberId', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.member_id = ?
      ORDER BY p.payment_date DESC
    `, [req.params.memberId]);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar pagamentos do membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/payments/period - Buscar pagamentos por período
router.get('/period', async (req, res) => {
  try {
    const { start, end } = req.query;

    const [rows] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.payment_date BETWEEN ? AND ?
      ORDER BY p.payment_date DESC
    `, [start, end]);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar pagamentos por período:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/payments/status/:status - Buscar pagamentos por status
router.get('/status/:status', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        p.id,
        p.member_id,
        p.amount,
        CONVERT_TZ(p.payment_date, '+00:00', '+01:00') as payment_date,
        p.status,
        p.payment_type,
        CONVERT_TZ(p.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(p.updated_at, '+00:00', '+01:00') as updated_at,
        m.name as member_name 
      FROM payments p
      LEFT JOIN members m ON p.member_id = m.id
      WHERE p.status = ?
      ORDER BY p.payment_date DESC
    `, [req.params.status]);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar pagamentos por status:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/payments/report - Gerar relatório de pagamentos
router.get('/report', async (req, res) => {
  try {
    const { start, end } = req.query;

    // Estatísticas gerais
    const [totalStats] = await pool.execute(`
      SELECT 
        COUNT(*) as total_payments,
        SUM(amount) as total_amount,
        AVG(amount) as average_amount
      FROM payments 
      WHERE payment_date BETWEEN ? AND ?
    `, [start, end]);

    // Pagamentos por status
    const [statusStats] = await pool.execute(`
      SELECT 
        status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments 
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY status
    `, [start, end]);

    // Pagamentos por período
    const [periodStats] = await pool.execute(`
      SELECT 
        DATE_FORMAT(CONVERT_TZ(payment_date, '+00:00', '+01:00'), '%Y-%m') as period,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments 
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY DATE_FORMAT(CONVERT_TZ(payment_date, '+00:00', '+01:00'), '%Y-%m')
      ORDER BY period
    `, [start, end]);

    // Pagamentos por mês
    const [monthlyStats] = await pool.execute(`
      SELECT 
        DATE_FORMAT(CONVERT_TZ(payment_date, '+00:00', '+01:00'), '%Y-%m') as month,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments 
      WHERE payment_date BETWEEN ? AND ?
      GROUP BY DATE_FORMAT(CONVERT_TZ(payment_date, '+00:00', '+01:00'), '%Y-%m')
      ORDER BY month
    `, [start, end]);

    res.json({
      period: { start, end },
      total: totalStats[0],
      byStatus: statusStats,
      byPeriod: periodStats,
      byMonth: monthlyStats
    });
  } catch (error) {
    console.error('Erro ao gerar relatório:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 