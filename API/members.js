const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/members - Buscar todos os membros
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        m.id,
        m.name,
        m.email,
        m.phone,
        m.membership_type,
        m.monthly_fee,
        CONVERT_TZ(m.join_date, '+00:00', '+01:00') as join_date,
        m.is_active,
        CONVERT_TZ(m.last_payment_date, '+00:00', '+01:00') as last_payment_date,
        CONVERT_TZ(m.next_payment_date, '+00:00', '+01:00') as next_payment_date,
        m.payment_status,
        CONVERT_TZ(m.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(m.updated_at, '+00:00', '+01:00') as updated_at,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            DATEDIFF(CURDATE(), m.next_payment_date)
          ELSE 0 
        END as days_overdue,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            FLOOR(DATEDIFF(CURDATE(), 
              COALESCE(m.last_payment_date, DATE_FORMAT(DATE_ADD(m.join_date, INTERVAL 1 MONTH), '%Y-%m-01'))
            ) / 
              CASE m.membership_type
                WHEN 'Mensal' THEN 30
                WHEN 'Trimestral' THEN 90
                WHEN 'Semestral' THEN 180
                WHEN 'Anual' THEN 365
                ELSE 30
              END
            ) + 1
          ELSE 0 
        END as overdue_months,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            (FLOOR(DATEDIFF(CURDATE(), 
              COALESCE(m.last_payment_date, DATE_FORMAT(DATE_ADD(m.join_date, INTERVAL 1 MONTH), '%Y-%m-01'))
            ) / 
              CASE m.membership_type
                WHEN 'Mensal' THEN 30
                WHEN 'Trimestral' THEN 90
                WHEN 'Semestral' THEN 180
                WHEN 'Anual' THEN 365
                ELSE 30
              END
            ) + 1) * m.monthly_fee
          ELSE 0 
        END as total_overdue
      FROM members m
      ORDER BY m.name ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar membros:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/members/overdue - Buscar membros em atraso
router.get('/overdue', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        m.id,
        m.name,
        m.email,
        m.phone,
        m.membership_type,
        m.monthly_fee,
        CONVERT_TZ(m.join_date, '+00:00', '+01:00') as join_date,
        m.is_active,
        CONVERT_TZ(m.last_payment_date, '+00:00', '+01:00') as last_payment_date,
        CONVERT_TZ(m.next_payment_date, '+00:00', '+01:00') as next_payment_date,
        m.payment_status,
        CONVERT_TZ(m.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(m.updated_at, '+00:00', '+01:00') as updated_at,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            DATEDIFF(CURDATE(), m.next_payment_date)
          ELSE 0 
        END as days_overdue,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            FLOOR(DATEDIFF(CURDATE(), 
              COALESCE(m.last_payment_date, DATE_FORMAT(DATE_ADD(m.join_date, INTERVAL 1 MONTH), '%Y-%m-01'))
            ) / 
              CASE m.membership_type
                WHEN 'Mensal' THEN 30
                WHEN 'Trimestral' THEN 90
                WHEN 'Semestral' THEN 180
                WHEN 'Anual' THEN 365
                ELSE 30
              END
            ) + 1
          ELSE 0 
        END as overdue_months,
        CASE 
          WHEN m.next_payment_date < CURDATE() THEN 
            (FLOOR(DATEDIFF(CURDATE(), 
              COALESCE(m.last_payment_date, DATE_FORMAT(DATE_ADD(m.join_date, INTERVAL 1 MONTH), '%Y-%m-01'))
            ) / 
              CASE m.membership_type
                WHEN 'Mensal' THEN 30
                WHEN 'Trimestral' THEN 90
                WHEN 'Semestral' THEN 180
                WHEN 'Anual' THEN 365
                ELSE 30
              END
            ) + 1) * m.monthly_fee
          ELSE 0 
        END as total_overdue
      FROM members m
      WHERE (m.next_payment_date < CURDATE() OR m.payment_status = 'overdue')
      AND m.is_active = 1
      ORDER BY m.next_payment_date ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar membros em atraso:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/members/payment-status/:status - Buscar membros por status de pagamento
router.get('/payment-status/:status', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        name,
        email,
        phone,
        membership_type,
        monthly_fee,
        CONVERT_TZ(join_date, '+00:00', '+01:00') as join_date,
        is_active,
        CONVERT_TZ(last_payment_date, '+00:00', '+01:00') as last_payment_date,
        CONVERT_TZ(next_payment_date, '+00:00', '+01:00') as next_payment_date,
        payment_status,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM members WHERE payment_status = ? ORDER BY name ASC
    `, [req.params.status]);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar membros por status:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/members/:id - Buscar membro por ID
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        name,
        email,
        phone,
        membership_type,
        monthly_fee,
        CONVERT_TZ(join_date, '+00:00', '+01:00') as join_date,
        is_active,
        CONVERT_TZ(last_payment_date, '+00:00', '+01:00') as last_payment_date,
        CONVERT_TZ(next_payment_date, '+00:00', '+01:00') as next_payment_date,
        payment_status,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM members WHERE id = ?
    `, [req.params.id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/members - Criar novo membro
router.post('/', async (req, res) => {
  try {
          const {
        name,
        email,
        phone,
        membership_type,
        monthly_fee,
        join_date,
        is_active
      } = req.body;

    // Calcular primeira data de pagamento (sempre dia 1 do mês seguinte ao ingresso)
    const joinDateObj = new Date(join_date);
    
    // Extrair ano e mês, lidando com fuso horário
    const year = joinDateObj.getFullYear();
    const month = joinDateObj.getMonth(); // 0-11
    
    // Calcular mês seguinte
    let nextMonth = month + 1;
    let nextYear = year;
    
    // Se passou de dezembro, ajustar para janeiro do ano seguinte
    if (nextMonth >= 12) {
      nextMonth = 0;
      nextYear++;
    }
    
    // Criar string de data no formato YYYY-MM-DD para fuso horário de Lisboa
    const firstPaymentDateStr = `${nextYear}-${String(nextMonth + 1).padStart(2, '0')}-01 00:00:00`;
    

    
    const [result] = await pool.execute(`
      INSERT INTO members (
        name, email, phone, membership_type, monthly_fee, 
        join_date, is_active, payment_status, 
        last_payment_date, next_payment_date, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    `, [
      name, email, phone, membership_type, monthly_fee,
      join_date, is_active ? 1 : 0, 'pending',
      null, firstPaymentDateStr
    ]);

    const [newMember] = await pool.execute(
      'SELECT * FROM members WHERE id = ?',
      [result.insertId]
    );



    res.status(201).json(newMember[0]);
  } catch (error) {
    console.error('Erro ao criar membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/members/:id - Atualizar membro
router.put('/:id', async (req, res) => {
  try {
    const {
      name,
      email,
      phone,
      membership_type,
      monthly_fee,
      join_date,
      is_active,
      last_payment_date,
      next_payment_date,
      payment_status
    } = req.body;



    await pool.execute(`
      UPDATE members SET 
        name = ?, email = ?, phone = ?, membership_type = ?, 
        monthly_fee = ?, join_date = ?, is_active = ?, 
        last_payment_date = ?, next_payment_date = ?, 
        payment_status = ?, updated_at = NOW()
      WHERE id = ?
    `, [
      name, email, phone, membership_type, monthly_fee,
      join_date, is_active ? 1 : 0, last_payment_date,
      next_payment_date, payment_status, req.params.id
    ]);

    const [updatedMember] = await pool.execute(
      'SELECT * FROM members WHERE id = ?',
      [req.params.id]
    );

    if (updatedMember.length === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }



    res.json(updatedMember[0]);
  } catch (error) {
    console.error('Erro ao atualizar membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/members/:id - Deletar membro e todas as informações relacionadas
router.delete('/:id', async (req, res) => {
  try {
    const memberId = req.params.id;
    
    // Verificar se o membro existe antes de deletar
    const [existingMember] = await pool.execute(
      'SELECT id, name FROM members WHERE id = ?',
      [memberId]
    );

    if (existingMember.length === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }

    const memberName = existingMember[0].name;
    
    // Contar pagamentos relacionados antes da exclusão
    const [paymentsCount] = await pool.execute(
      'SELECT COUNT(*) as count FROM payments WHERE member_id = ?',
      [memberId]
    );
    
    const totalPayments = paymentsCount[0].count;
    
    // Iniciar transação para garantir consistência
    await pool.execute('START TRANSACTION');
    
    try {
      // Deletar o membro (os pagamentos serão automaticamente removidos devido ao ON DELETE CASCADE)
      const [result] = await pool.execute(
        'DELETE FROM members WHERE id = ?',
        [memberId]
      );

      if (result.affectedRows === 0) {
        await pool.execute('ROLLBACK');
        return res.status(404).json({ error: 'Membro não encontrado' });
      }

      // Confirmar transação
      await pool.execute('COMMIT');
      
      // Log da exclusão completa
      console.log(`Membro "${memberName}" (ID: ${memberId}) foi completamente removido da base de dados.`);
      console.log(`- ${totalPayments} pagamento(s) relacionado(s) também foram removido(s) automaticamente.`);
      
      res.json({ 
        message: 'Membro e todas as informações relacionadas foram removidos com sucesso',
        details: {
          memberName: memberName,
          memberId: memberId,
          paymentsRemoved: totalPayments
        }
      });
      
    } catch (deleteError) {
      // Em caso de erro, reverter transação
      await pool.execute('ROLLBACK');
      throw deleteError;
    }
    
  } catch (error) {
    console.error('Erro ao deletar membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/members/verify-deletion/:id - Verificar se a exclusão foi completa
router.get('/verify-deletion/:id', async (req, res) => {
  try {
    const memberId = req.params.id;
    
    // Verificar se o membro ainda existe
    const [memberExists] = await pool.execute(
      'SELECT id, name FROM members WHERE id = ?',
      [memberId]
    );
    
    // Verificar se há pagamentos relacionados
    const [paymentsExist] = await pool.execute(
      'SELECT COUNT(*) as count FROM payments WHERE member_id = ?',
      [memberId]
    );
    
    const verification = {
      memberExists: memberExists.length > 0,
      memberName: memberExists.length > 0 ? memberExists[0].name : null,
      paymentsExist: paymentsExist[0].count > 0,
      paymentsCount: paymentsExist[0].count,
      deletionComplete: memberExists.length === 0 && paymentsExist[0].count === 0,
      timestamp: new Date().toISOString()
    };
    
    res.json(verification);
  } catch (error) {
    console.error('Erro ao verificar exclusão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 