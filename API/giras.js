const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/giras - Buscar todas as Giras
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras 
      ORDER BY date ASC, time ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar Giras:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/active - Buscar Giras ativas (não passadas)
router.get('/active', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras 
      WHERE is_past = 0 AND status = 'active'
      ORDER BY date ASC, time ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar Giras ativas:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/past - Buscar Giras passadas
router.get('/past', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras 
      WHERE is_past = 1
      ORDER BY date DESC, time DESC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar Giras passadas:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/:id - Buscar Gira por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras WHERE id = ?
    `, [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar Gira:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/giras - Criar nova Gira
router.post('/', async (req, res) => {
  try {
    const {
      title,
      orixa_name,
      date,
      time,
      description,
      max_participants,
      status
    } = req.body;
    
    // Validações básicas
    if (!title || !orixa_name || !date || !time) {
      return res.status(400).json({ 
        error: 'Título, Orixá, data e hora são obrigatórios' 
      });
    }
    
    // Verificar se a data é no futuro
    const giraDate = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const isPast = giraDate < today;
    
    const [result] = await pool.execute(`
      INSERT INTO giras (
        title, orixa_name, date, time, description, 
        is_past, max_participants, 
        current_participants, status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    `, [
      title, orixa_name, date, time, description || '',
      isPast ? 1 : 0, max_participants || 0,
      0, status || 'active'
    ]);
    
    // Buscar a Gira recém-criada
    const [newGira] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras WHERE id = ?
    `, [result.insertId]);
    
    res.status(201).json(newGira[0]);
  } catch (error) {
    console.error('Erro ao criar Gira:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/giras/:id - Atualizar Gira existente
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      orixa_name,
      date,
      time,
      description,
      max_participants,
      status
    } = req.body;
    
    // Verificar se a Gira existe
    const [existing] = await pool.execute(
      'SELECT id FROM giras WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    // Verificar se a data é no futuro
    const giraDate = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const isPast = giraDate < today;
    
    await pool.execute(`
      UPDATE giras SET 
        title = ?, orixa_name = ?, date = ?, time = ?, 
        description = ?, is_past = ?,
        max_participants = ?, status = ?, updated_at = NOW()
      WHERE id = ?
    `, [
      title, orixa_name, date, time, description || '',
      isPast ? 1 : 0, max_participants || 0,
      status || 'active', id
    ]);
    
    // Buscar a Gira atualizada
    const [updatedGira] = await pool.execute(`
      SELECT 
        id,
        title,
        orixa_name,
        DATE_FORMAT(date, '%Y-%m-%d') as date,
        time,
        description,
        is_past,
        max_participants,
        current_participants,
        status
      FROM giras WHERE id = ?
    `, [id]);
    
    res.json(updatedGira[0]);
  } catch (error) {
    console.error('Erro ao atualizar Gira:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/giras/:id - Deletar Gira
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se a Gira existe
    const [existing] = await pool.execute(
      'SELECT id, title FROM giras WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    const giraTitle = existing[0].title;
    
    // Deletar a Gira
    await pool.execute('DELETE FROM giras WHERE id = ?', [id]);
    
    res.json({ 
      message: 'Gira deletada com sucesso',
      deletedGira: {
        id: id,
        title: giraTitle
      }
    });
  } catch (error) {
    console.error('Erro ao deletar Gira:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/giras/:id/participate - Participar numa Gira
router.post('/:id/participate', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      participant_name, 
      participant_email, 
      participant_phone, 
      companions,
      notes 
    } = req.body;
    
    if (!participant_name || !participant_email) {
      return res.status(400).json({ 
        error: 'Nome e email do participante são obrigatórios' 
      });
    }
    
    // Verificar se a Gira existe e está ativa
    const [gira] = await pool.execute(`
      SELECT id, title, is_past, status, max_participants, current_participants
      FROM giras WHERE id = ?
    `, [id]);
    
    if (gira.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    if (gira[0].is_past) {
      return res.status(400).json({ error: 'Não é possível participar numa Gira que já passou' });
    }
    
    if (gira[0].status !== 'active') {
      return res.status(400).json({ error: 'Esta Gira não está ativa para participações' });
    }
    
    // Verificar se há vagas disponíveis
    if (gira[0].max_participants > 0 && 
        gira[0].current_participants >= gira[0].max_participants) {
      return res.status(400).json({ error: 'Esta Gira já está lotada' });
    }
    
    // Verificar se o participante já está inscrito
    const [existingParticipant] = await pool.execute(
      'SELECT id FROM gira_participants WHERE gira_id = ? AND participant_email = ?',
      [id, participant_email]
    );
    
    if (existingParticipant.length > 0) {
      return res.status(400).json({ error: 'Já participas nesta Gira' });
    }
    
    // Iniciar transação
    await pool.execute('START TRANSACTION');
    
    try {
      // Inserir participante com status pendente
      const [result] = await pool.execute(`
        INSERT INTO gira_participants (
          gira_id, participant_name, participant_email, 
          participant_phone, companions, notes, status
        ) VALUES (?, ?, ?, ?, ?, ?, 'pending')
      `, [id, participant_name, participant_email, participant_phone || null, companions || 0, notes || null]);
      
      // Não incrementar contador automaticamente - apenas participações confirmadas contam
      
      // Confirmar transação
      await pool.execute('COMMIT');
      
      // Buscar dados do participante criado
      const [newParticipant] = await pool.execute(`
        SELECT 
          id, gira_id, participant_name, participant_email, 
          participant_phone, companions, notes, status,
          CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at
        FROM gira_participants WHERE id = ?
      `, [result.insertId]);
      
      res.status(201).json({ 
        message: 'Participação registada e aguarda aprovação',
        gira: gira[0].title,
        participant: participant_name,
        status: 'pending',
        participantData: newParticipant[0]
      });
      
    } catch (transactionError) {
      // Reverter transação em caso de erro
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao registar participação:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/:id/participants - Listar participantes de uma Gira
router.get('/:id/participants', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se a Gira existe
    const [gira] = await pool.execute(
      'SELECT id, title FROM giras WHERE id = ?',
      [id]
    );
    
    if (gira.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    // Buscar participantes da Gira
    const [participants] = await pool.execute(`
      SELECT 
        id,
        participant_name,
        participant_email,
        participant_phone,
        companions,
        notes,
        status,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at
      FROM gira_participants 
      WHERE gira_id = ? AND status = 'confirmed'
      ORDER BY created_at ASC
    `, [id]);
    
    res.json({ 
      gira: gira[0].title,
      participants: participants,
      total: participants.length
    });
  } catch (error) {
    console.error('Erro ao listar participantes:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/giras/:id/participate - Cancelar participação numa Gira
router.delete('/:id/participate', async (req, res) => {
  try {
    const { id } = req.params;
    const { participant_email } = req.body;
    
    if (!participant_email) {
      return res.status(400).json({ 
        error: 'Email do participante é obrigatório' 
      });
    }
    
    // Verificar se a Gira existe
    const [gira] = await pool.execute(
      'SELECT id, title, is_past, status FROM giras WHERE id = ?',
      [id]
    );
    
    if (gira.length === 0) {
      return res.status(404).json({ error: 'Gira não encontrada' });
    }
    
    if (gira[0].is_past) {
      return res.status(400).json({ error: 'Não é possível cancelar participação numa Gira que já passou' });
    }
    
    // Verificar se o participante está inscrito
    const [participant] = await pool.execute(
      'SELECT id, participant_name FROM gira_participants WHERE gira_id = ? AND participant_email = ? AND status = "confirmed"',
      [id, participant_email]
    );
    
    if (participant.length === 0) {
      return res.status(404).json({ error: 'Participação não encontrada' });
    }
    
    // Iniciar transação
    await pool.execute('START TRANSACTION');
    
    try {
      // Cancelar participação (mudar status para cancelled)
      await pool.execute(
        'UPDATE gira_participants SET status = "cancelled", updated_at = NOW() WHERE id = ?',
        [participant[0].id]
      );
      
      // Decrementar contador de participantes na Gira
      await pool.execute(
        'UPDATE giras SET current_participants = GREATEST(current_participants - 1, 0) WHERE id = ?',
        [id]
      );
      
      // Confirmar transação
      await pool.execute('COMMIT');
      
      res.json({ 
        message: 'Participação cancelada com sucesso',
        gira: gira[0].title,
        participant: participant[0].participant_name
      });
      
    } catch (transactionError) {
      // Reverter transação em caso de erro
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao cancelar participação:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/test - Endpoint de teste
router.get('/test', async (req, res) => {
  res.json({ 
    message: 'API de Giras funcionando!',
    timestamp: new Date().toISOString(),
    endpoints: [
      'GET /api/giras - Listar giras',
      'POST /api/giras/participations/user - Participações do utilizador',
      'POST /api/giras/:id/participate - Participar numa gira',
      'DELETE /api/giras/:id/participate - Cancelar participação'
    ]
  });
});

// POST /api/giras/participations/user - Obter participações de um utilizador
router.post('/participations/user', async (req, res) => {
  try {
    const { participant_email } = req.body;
    
    if (!participant_email) {
      return res.status(400).json({ 
        error: 'Email do participante é obrigatório' 
      });
    }
    
    console.log(`Buscando participações para email: ${participant_email}`);
    
    // Buscar participações do utilizador com informações da Gira
    const [participations] = await pool.execute(`
      SELECT 
        gp.id,
        gp.gira_id,
        gp.participant_name,
        gp.participant_email,
        gp.participant_phone,
        gp.companions,
        gp.notes,
        gp.status,
        gp.admin_name,
        gp.admin_action,
        gp.admin_notes,
        CONVERT_TZ(gp.created_at, '+00:00', '+01:00') as created_at,
        g.title as gira_title,
        g.orixa_name,
        g.date,
        g.time,
        g.description as gira_description,
        g.is_past,
        g.max_participants,
        g.current_participants,
        g.status as gira_status
      FROM gira_participants gp
      JOIN giras g ON gp.gira_id = g.id
      WHERE gp.participant_email = ? AND gp.status IN ('confirmed', 'pending')
      ORDER BY g.date ASC, g.time ASC
    `, [participant_email]);
    
    console.log(`Encontradas ${participations.length} participações para ${participant_email}`);
    
    res.json({ 
      participations: participations,
      total: participations.length,
      participant_email: participant_email
    });
    
  } catch (error) {
    console.error('Erro ao obter participações do utilizador:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/giras/:id/check-participation - Verificar se utilizador já participa
router.post('/:id/check-participation', async (req, res) => {
  try {
    const { id } = req.params;
    const { participant_email } = req.body;
    
    if (!id || !participant_email) {
      return res.status(400).json({ 
        error: 'ID da Gira e email são obrigatórios' 
      });
    }
    
    console.log(`Verificando participação de ${participant_email} na Gira ${id}`);
    
    // Verificar se o participante já está inscrito (confirmado ou pendente)
    const [existingParticipant] = await pool.execute(`
      SELECT 
        id, participant_name, participant_email, participant_phone, 
        companions, notes, status, 
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at
      FROM gira_participants 
      WHERE gira_id = ? AND participant_email = ? AND status IN ('confirmed', 'pending')
    `, [id, participant_email]);
    
    const isParticipating = existingParticipant.length > 0;
    
    console.log(`Participação encontrada: ${isParticipating}`);
    
    res.json({
      isParticipating: isParticipating,
      participantData: isParticipating ? existingParticipant[0] : null,
      gira_id: parseInt(id),
      participant_email: participant_email
    });
    
  } catch (error) {
    console.error('Erro ao verificar participação:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/giras/participations/:id/status - Aprovar/Rejeitar participação (Admin)
router.put('/participations/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_notes, admin_name } = req.body;
    
    if (!id) {
      return res.status(400).json({ 
        error: 'ID da participação é obrigatório' 
      });
    }
    
    if (!status || !['confirmed', 'cancelled'].includes(status)) {
      return res.status(400).json({ 
        error: 'Status deve ser "confirmed" ou "cancelled"' 
      });
    }
    
    console.log(`Alterando status da participação ${id} para ${status}`);
    
    // Verificar se a participação existe
    const [participation] = await pool.execute(`
      SELECT gp.*, g.title as gira_title
      FROM gira_participants gp
      JOIN giras g ON gp.gira_id = g.id
      WHERE gp.id = ?
    `, [id]);
    
    if (participation.length === 0) {
      return res.status(404).json({ error: 'Participação não encontrada' });
    }
    
    const participationData = participation[0];
    
    // Iniciar transação
    await pool.execute('START TRANSACTION');
    
    try {
      // Atualizar status da participação e informações administrativas
      await pool.execute(`
        UPDATE gira_participants 
        SET status = ?, admin_name = ?, admin_action = ?, admin_notes = ?
        WHERE id = ?
      `, [
        status, 
        admin_name || null, 
        status === 'confirmed' ? 'approved' : 'rejected',
        admin_notes || null, 
        id
      ]);
      
      // Atualizar contador de participantes na Gira
      if (status === 'confirmed') {
        // Se foi confirmado, incrementar contador
        await pool.execute(
          'UPDATE giras SET current_participants = current_participants + 1 WHERE id = ?',
          [participationData.gira_id]
        );
      } else if (status === 'cancelled' && participationData.status === 'confirmed') {
        // Se foi cancelado e estava confirmado antes, decrementar contador
        await pool.execute(
          'UPDATE giras SET current_participants = current_participants - 1 WHERE id = ?',
          [participationData.gira_id]
        );
      }
      
      // Confirmar transação
      await pool.execute('COMMIT');
      
      // Buscar dados atualizados
      const [updatedParticipation] = await pool.execute(`
        SELECT 
          gp.*, g.title as gira_title,
          CONVERT_TZ(gp.updated_at, '+00:00', '+01:00') as updated_at
        FROM gira_participants gp
        JOIN giras g ON gp.gira_id = g.id
        WHERE gp.id = ?
      `, [id]);
      

      
      res.json({ 
        message: `Participação ${status === 'confirmed' ? 'aprovada' : 'rejeitada'} com sucesso`,
        participation: updatedParticipation[0],
        previous_status: participationData.status,
        new_status: status
      });
      
    } catch (transactionError) {
      // Reverter transação em caso de erro
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao alterar status da participação:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/participations/pending - Listar participações pendentes (Admin)
router.get('/participations/pending', async (req, res) => {
  try {
    console.log('Buscando participações pendentes');
    
    // Buscar participações pendentes com informações da Gira
    const [participations] = await pool.execute(`
      SELECT 
        gp.id,
        gp.gira_id,
        gp.participant_name,
        gp.participant_email,
        gp.participant_phone,
        gp.companions,
        gp.notes,
        gp.status,
        gp.admin_name,
        gp.admin_action,
        gp.admin_notes,
        CONVERT_TZ(gp.created_at, '+00:00', '+01:00') as created_at,
        g.title as gira_title,
        g.orixa_name,
        g.date,
        g.time,
        g.max_participants,
        g.current_participants
      FROM gira_participants gp
      JOIN giras g ON gp.gira_id = g.id
      WHERE gp.status = 'pending'
      ORDER BY gp.created_at DESC
    `);
    
    console.log(`Encontradas ${participations.length} participações pendentes`);
    
    res.json({ 
      participations: participations,
      total: participations.length
    });
    
  } catch (error) {
    console.error('Erro ao obter participações pendentes:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/giras/participations/all - Listar todas as participações (Admin)
router.get('/participations/all', async (req, res) => {
  try {
    console.log('Buscando todas as participações');
    
    // Buscar todas as participações com informações da Gira
    const [participations] = await pool.execute(`
      SELECT 
        gp.id,
        gp.gira_id,
        gp.participant_name,
        gp.participant_email,
        gp.participant_phone,
        gp.companions,
        gp.notes,
        gp.status,
        gp.admin_name,
        gp.admin_action,
        gp.admin_notes,
        CONVERT_TZ(gp.created_at, '+00:00', '+01:00') as created_at,
        g.title as gira_title,
        g.orixa_name,
        g.date,
        g.time,
        g.max_participants,
        g.current_participants
      FROM gira_participants gp
      JOIN giras g ON gp.gira_id = g.id
      ORDER BY g.date ASC, g.time ASC, gp.created_at ASC
    `);
    
    console.log(`Encontradas ${participations.length} participações no total`);
    
    res.json({ 
      participations: participations,
      total: participations.length
    });
    
  } catch (error) {
    console.error('Erro ao obter todas as participações:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router;
