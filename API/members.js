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
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
            DATEDIFF(CURDATE(), m.next_payment_date)
          ELSE 0 
        END as days_overdue,
        CASE 
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
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
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
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
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
            DATEDIFF(CURDATE(), m.next_payment_date)
          ELSE 0 
        END as days_overdue,
        CASE 
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
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
          WHEN m.next_payment_date < CURDATE() AND m.is_active = 1 THEN 
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

    // Validações básicas
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Nome é obrigatório' });
    }
    
    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ error: 'Telefone é obrigatório' });
    }
    
    if (!membership_type || membership_type.trim().length === 0) {
      return res.status(400).json({ error: 'Tipo de mensalidade é obrigatório' });
    }
    
    if (!monthly_fee || isNaN(monthly_fee) || monthly_fee <= 0) {
      return res.status(400).json({ error: 'Valor da mensalidade deve ser um número positivo' });
    }
    
    if (!join_date) {
      return res.status(400).json({ error: 'Data de adesão é obrigatória' });
    }

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
      name, 
      email && email.trim() !== '' ? email : null, // Usar NULL em vez de string vazia
      phone, 
      membership_type, 
      monthly_fee,
      join_date, 
      is_active ? 1 : 0, 
      'pending',
      null, 
      firstPaymentDateStr
    ]);

    const [newMember] = await pool.execute(
      'SELECT * FROM members WHERE id = ?',
      [result.insertId]
    );



    res.status(201).json(newMember[0]);
  } catch (error) {
    console.error('Erro ao criar membro:', error);
    console.error('Stack trace:', error.stack);
    
    // Verificar se é erro de duplicação (email ou telefone únicos)
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Já existe um membro com este email ou telefone' });
    }
    
    // Verificar se é erro de validação da base de dados
    if (error.code === 'ER_BAD_NULL_ERROR') {
      return res.status(400).json({ error: 'Dados obrigatórios em falta' });
    }
    
    // Verificar se é erro de tipo de dados
    if (error.code === 'ER_TRUNCATED_WRONG_VALUE' || error.code === 'ER_WRONG_VALUE') {
      return res.status(400).json({ error: 'Formato de dados inválido' });
    }
    
    res.status(500).json({ 
      error: 'Erro interno do servidor',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
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

    // Buscar dados atuais do membro para verificar mudança de status
    const [currentMember] = await pool.execute(
      'SELECT is_active, next_payment_date FROM members WHERE id = ?',
      [req.params.id]
    );

    if (currentMember.length === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }

    const wasActive = currentMember[0].is_active;
    const willBeActive = is_active ? 1 : 0;

    // Se o membro estava inativo e agora vai ficar ativo, reiniciar contagem
    if (!wasActive && willBeActive) {
      const today = new Date();
      const year = today.getFullYear();
      const month = today.getMonth() + 1; // getMonth() retorna 0-11
      
      // Calcular próxima data de pagamento (dia 1 do próximo mês)
      let nextMonth = month + 1;
      let nextYear = year;
      
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      
      const newNextPaymentDate = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01 00:00:00`;
      
      await pool.execute(`
        UPDATE members SET 
          name = ?, email = ?, phone = ?, membership_type = ?, 
          monthly_fee = ?, join_date = ?, is_active = ?, 
          last_payment_date = ?, next_payment_date = ?, 
          payment_status = ?, updated_at = NOW()
        WHERE id = ?
      `, [
        name, 
        email && email.trim() !== '' ? email : null,
        phone, 
        membership_type, 
        monthly_fee,
        join_date, 
        willBeActive, 
        null, // Limpar último pagamento ao reativar
        newNextPaymentDate, // Nova data de pagamento
        'pending', // Status pendente ao reativar
        req.params.id
      ]);
    } else {
      // Atualização normal sem mudança de status ativo/inativo
      await pool.execute(`
        UPDATE members SET 
          name = ?, email = ?, phone = ?, membership_type = ?, 
          monthly_fee = ?, join_date = ?, is_active = ?, 
          last_payment_date = ?, next_payment_date = ?, 
          payment_status = ?, updated_at = NOW()
        WHERE id = ?
      `, [
        name, 
        email && email.trim() !== '' ? email : null,
        phone, 
        membership_type, 
        monthly_fee,
        join_date, 
        willBeActive, 
        last_payment_date,
        next_payment_date, 
        payment_status, 
        req.params.id
      ]);
    }

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
    let totalPayments = 0;
    try {
      const [paymentsCount] = await pool.execute(
        'SELECT COUNT(*) as count FROM payments WHERE member_id = ?',
        [memberId]
      );
      totalPayments = paymentsCount[0].count;
    } catch (error) {
      // Se houver erro ao contar pagamentos, continuar sem contar
      totalPayments = 0;
    }
    
    // Deletar o membro (os pagamentos serão automaticamente removidos devido ao ON DELETE CASCADE)
    const [result] = await pool.execute(
      'DELETE FROM members WHERE id = ?',
      [memberId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }
    
    res.json({ 
      message: 'Membro e todas as informações relacionadas foram removidos com sucesso',
      details: {
        memberName: memberName,
        memberId: memberId,
        paymentsRemoved: totalPayments
      }
    });
    
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
    
    // Verificar se há pagamentos relacionados (se a tabela existir)
    let paymentsExist = false;
    let paymentsCount = 0;
    try {
      const [paymentsResult] = await pool.execute(
        'SELECT COUNT(*) as count FROM payments WHERE member_id = ?',
        [memberId]
      );
      paymentsExist = paymentsResult[0].count > 0;
      paymentsCount = paymentsResult[0].count;
    } catch (error) {
      // Se a tabela payments não existir, assumir que não há pagamentos
      console.log('Aviso: Tabela payments não encontrada na verificação');
      paymentsExist = false;
      paymentsCount = 0;
    }
    
    const verification = {
      memberExists: memberExists.length > 0,
      memberName: memberExists.length > 0 ? memberExists[0].name : null,
      paymentsExist: paymentsExist,
      paymentsCount: paymentsCount,
      deletionComplete: memberExists.length === 0 && !paymentsExist,
      timestamp: new Date().toISOString()
    };
    
    res.json(verification);
  } catch (error) {
    console.error('Erro ao verificar exclusão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/members/:id/toggle-status - Ativar/Desativar membro
router.put('/:id/toggle-status', async (req, res) => {
  try {
    const { is_active } = req.body;
    
    if (typeof is_active !== 'boolean') {
      return res.status(400).json({ error: 'is_active deve ser true ou false' });
    }

    // Buscar dados atuais do membro
    const [currentMember] = await pool.execute(
      'SELECT id, name, is_active, next_payment_date FROM members WHERE id = ?',
      [req.params.id]
    );

    if (currentMember.length === 0) {
      return res.status(404).json({ error: 'Membro não encontrado' });
    }

    const member = currentMember[0];
    const wasActive = member.is_active;
    const willBeActive = is_active ? 1 : 0;

    // Se não há mudança de status, retornar sem fazer nada
    if (wasActive === willBeActive) {
      return res.json({ 
        message: `Membro já está ${is_active ? 'ativo' : 'inativo'}`,
        member: member
      });
    }

    if (!wasActive && willBeActive) {
      // Reativar membro - reiniciar contagem como novo membro
      const today = new Date();
      const year = today.getFullYear();
      const month = today.getMonth() + 1;
      
      let nextMonth = month + 1;
      let nextYear = year;
      
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      
      const newNextPaymentDate = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01 00:00:00`;
      
      await pool.execute(`
        UPDATE members SET 
          is_active = ?, 
          last_payment_date = NULL,
          next_payment_date = ?,
          payment_status = 'pending',
          updated_at = NOW()
        WHERE id = ?
      `, [willBeActive, newNextPaymentDate, req.params.id]);

      res.json({ 
        message: 'Membro reativado com sucesso. Contagem de mensalidades reiniciada.',
        action: 'reactivated',
        newNextPaymentDate: newNextPaymentDate
      });
    } else {
      // Desativar membro - suspender contagem
      await pool.execute(`
        UPDATE members SET 
          is_active = ?, 
          payment_status = 'suspended',
          updated_at = NOW()
        WHERE id = ?
      `, [willBeActive, req.params.id]);

      res.json({ 
        message: 'Membro desativado com sucesso. Contagem de mensalidades suspensa.',
        action: 'deactivated'
      });
    }

  } catch (error) {
    console.error('Erro ao alterar status do membro:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router; 