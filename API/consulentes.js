const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/consulentes - Buscar todos os consulentes
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.execute(`
      SELECT 
        id,
        name,
        phone,
        email,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulentes 
      ORDER BY name ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar consulentes:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/consulentes/:id - Buscar consulente por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.execute(`
      SELECT 
        id,
        name,
        phone,
        email,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulentes WHERE id = ?
    `, [id]);
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar consulente:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/consulentes - Criar novo consulente
router.post('/', async (req, res) => {
  try {
    const { name, phone, email, notes } = req.body;
    
    // Validações básicas
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Nome é obrigatório' });
    }
    
    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ error: 'Telefone é obrigatório' });
    }
    
    const [result] = await pool.execute(`
      INSERT INTO consulentes (name, phone, email, notes, created_at)
      VALUES (?, ?, ?, ?, NOW())
    `, [
      name.trim(), 
      phone.trim(), 
      email && email.trim() !== '' ? email.trim() : null,
      notes && notes.trim() !== '' ? notes.trim() : null
    ]);
    
    // Buscar o consulente recém-criado
    const [newConsulente] = await pool.execute(`
      SELECT 
        id,
        name,
        phone,
        email,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulentes WHERE id = ?
    `, [result.insertId]);
    
    res.status(201).json(newConsulente[0]);
  } catch (error) {
    console.error('Erro ao criar consulente:', error);
    
    // Verificar se é erro de duplicação
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Já existe um consulente com este telefone ou email' });
    }
    
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/consulentes/:id - Atualizar consulente
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, email, notes } = req.body;
    
    // Verificar se o consulente existe
    const [existing] = await pool.execute(
      'SELECT id FROM consulentes WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    // Validações básicas
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Nome é obrigatório' });
    }
    
    if (!phone || phone.trim().length === 0) {
      return res.status(400).json({ error: 'Telefone é obrigatório' });
    }
    
    await pool.execute(`
      UPDATE consulentes SET 
        name = ?, phone = ?, email = ?, notes = ?, updated_at = NOW()
      WHERE id = ?
    `, [
      name.trim(), 
      phone.trim(), 
      email && email.trim() !== '' ? email.trim() : null,
      notes && notes.trim() !== '' ? notes.trim() : null,
      id
    ]);
    
    // Buscar o consulente atualizado
    const [updatedConsulente] = await pool.execute(`
      SELECT 
        id,
        name,
        phone,
        email,
        notes,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulentes WHERE id = ?
    `, [id]);
    
    res.json(updatedConsulente[0]);
  } catch (error) {
    console.error('Erro ao atualizar consulente:', error);
    
    // Verificar se é erro de duplicação
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Já existe um consulente com este telefone ou email' });
    }
    
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/consulentes/:id - Deletar consulente
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se o consulente existe
    const [existing] = await pool.execute(
      'SELECT id, name FROM consulentes WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    const consulenteName = existing[0].name;
    
    // Contar sessões relacionadas antes da exclusão
    let totalSessions = 0;
    try {
      const [sessionsCount] = await pool.execute(
        'SELECT COUNT(*) as count FROM consulente_sessions WHERE consulente_id = ?',
        [id]
      );
      totalSessions = sessionsCount[0].count;
    } catch (error) {
      totalSessions = 0;
    }
    
    // Deletar o consulente (as sessões serão automaticamente removidas devido ao ON DELETE CASCADE)
    const [result] = await pool.execute(
      'DELETE FROM consulentes WHERE id = ?',
      [id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    res.json({ 
      message: 'Consulente e todas as informações relacionadas foram removidos com sucesso',
      details: {
        consulenteName: consulenteName,
        consulenteId: id,
        sessionsRemoved: totalSessions
      }
    });
    
  } catch (error) {
    console.error('Erro ao deletar consulente:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/consulentes/:id/sessions - Listar sessões de um consulente
router.get('/:id/sessions', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se o consulente existe
    const [consulente] = await pool.execute(
      'SELECT id, name FROM consulentes WHERE id = ?',
      [id]
    );
    
    if (consulente.length === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    // Buscar sessões do consulente
    const [sessions] = await pool.execute(`
      SELECT 
        id,
        consulente_id,
        CONVERT_TZ(session_date, '+00:00', '+01:00') as session_date,
        description,
        notes,
        acompanhantes_ids,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulente_sessions 
      WHERE consulente_id = ?
      ORDER BY session_date DESC
    `, [id]);
    
    res.json({ 
      consulente: consulente[0].name,
      sessions: sessions,
      total: sessions.length
    });
  } catch (error) {
    console.error('Erro ao listar sessões:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/consulentes/:id/sessions - Adicionar nova sessão
router.post('/:id/sessions', async (req, res) => {
  try {
    const { id } = req.params;
    const { session_date, description, notes, acompanhantes_ids } = req.body;
    
    // Verificar se o consulente existe
    const [consulente] = await pool.execute(
      'SELECT id, name FROM consulentes WHERE id = ?',
      [id]
    );
    
    if (consulente.length === 0) {
      return res.status(404).json({ error: 'Consulente não encontrado' });
    }
    
    // Validações básicas
    if (!session_date) {
      return res.status(400).json({ error: 'Data da sessão é obrigatória' });
    }
    
    if (!description || description.trim().length === 0) {
      return res.status(400).json({ error: 'Descrição é obrigatória' });
    }
    
    // Validar acompanhantes se fornecidos
    let acompanhantesJson = null;
    if (acompanhantes_ids && Array.isArray(acompanhantes_ids) && acompanhantes_ids.length > 0) {
      // Verificar se todos os acompanhantes existem
      const placeholders = acompanhantes_ids.map(() => '?').join(',');
      const [acompanhantes] = await pool.execute(
        `SELECT id FROM consulentes WHERE id IN (${placeholders})`,
        acompanhantes_ids
      );
      
      if (acompanhantes.length !== acompanhantes_ids.length) {
        return res.status(400).json({ error: 'Um ou mais acompanhantes não existem' });
      }
      
      acompanhantesJson = JSON.stringify(acompanhantes_ids);
    }
    
    const [result] = await pool.execute(`
      INSERT INTO consulente_sessions (consulente_id, session_date, description, notes, acompanhantes_ids, created_at)
      VALUES (?, ?, ?, ?, ?, NOW())
    `, [
      id,
      session_date,
      description.trim(),
      notes && notes.trim() !== '' ? notes.trim() : null,
      acompanhantesJson
    ]);
    
    // Criar automaticamente um registo de presença para esta sessão
    const sessionDate = new Date(session_date).toISOString().split('T')[0]; // Extrair apenas a data (YYYY-MM-DD)
    
    // Verificar se já existe um registo de presença para este consulente nesta data
    const [existingAttendance] = await pool.execute(
      'SELECT id FROM attendance_records WHERE consulente_id = ? AND attendance_date = ?',
      [id, sessionDate]
    );
    
    // Se não existir, criar um registo de presença como "pending"
    if (existingAttendance.length === 0) {
      await pool.execute(`
        INSERT INTO attendance_records (consulente_id, attendance_date, status, notes, created_at)
        VALUES (?, ?, 'pending', ?, NOW())
      `, [
        id,
        sessionDate,
        `Presença automática (Pendente) - Sessão: ${description.trim()}`
      ]);
    }
    
    // Criar registos de presença para acompanhantes também
    if (acompanhantes_ids && acompanhantes_ids.length > 0) {
      for (const acompanhanteId of acompanhantes_ids) {
        const [existingAcompanhanteAttendance] = await pool.execute(
          'SELECT id FROM attendance_records WHERE consulente_id = ? AND attendance_date = ?',
          [acompanhanteId, sessionDate]
        );
        
        if (existingAcompanhanteAttendance.length === 0) {
          await pool.execute(`
            INSERT INTO attendance_records (consulente_id, attendance_date, status, notes, created_at)
            VALUES (?, ?, 'pending', ?, NOW())
          `, [
            acompanhanteId,
            sessionDate,
            `Presença automática (Pendente) - Acompanhante da sessão: ${description.trim()}`
          ]);
        }
      }
    }
    
    // Buscar a sessão recém-criada
    const [newSession] = await pool.execute(`
      SELECT 
        id,
        consulente_id,
        CONVERT_TZ(session_date, '+00:00', '+01:00') as session_date,
        description,
        notes,
        acompanhantes_ids,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulente_sessions WHERE id = ?
    `, [result.insertId]);
    
    res.status(201).json(newSession[0]);
  } catch (error) {
    console.error('Erro ao criar sessão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/consulentes/sessions/:id - Atualizar sessão
router.put('/sessions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { session_date, description, notes, acompanhantes_ids } = req.body;
    
    // Verificar se a sessão existe
    const [existing] = await pool.execute(
      'SELECT id FROM consulente_sessions WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Sessão não encontrada' });
    }
    
    // Validações básicas
    if (!session_date) {
      return res.status(400).json({ error: 'Data da sessão é obrigatória' });
    }
    
    if (!description || description.trim().length === 0) {
      return res.status(400).json({ error: 'Descrição é obrigatória' });
    }
    
    // Validar acompanhantes se fornecidos
    let acompanhantesJson = null;
    if (acompanhantes_ids && Array.isArray(acompanhantes_ids) && acompanhantes_ids.length > 0) {
      // Verificar se todos os acompanhantes existem
      const placeholders = acompanhantes_ids.map(() => '?').join(',');
      const [acompanhantes] = await pool.execute(
        `SELECT id FROM consulentes WHERE id IN (${placeholders})`,
        acompanhantes_ids
      );
      
      if (acompanhantes.length !== acompanhantes_ids.length) {
        return res.status(400).json({ error: 'Um ou mais acompanhantes não existem' });
      }
      
      acompanhantesJson = JSON.stringify(acompanhantes_ids);
    }
    
    await pool.execute(`
      UPDATE consulente_sessions SET 
        session_date = ?, description = ?, notes = ?, acompanhantes_ids = ?, updated_at = NOW()
      WHERE id = ?
    `, [
      session_date,
      description.trim(),
      notes && notes.trim() !== '' ? notes.trim() : null,
      acompanhantesJson,
      id
    ]);
    
    // Atualizar também o registo de presença se existir
    const sessionDate = new Date(session_date).toISOString().split('T')[0];
    
    // Buscar o consulente_id da sessão atualizada
    const [sessionInfo] = await pool.execute(
      'SELECT consulente_id FROM consulente_sessions WHERE id = ?',
      [id]
    );
    
    if (sessionInfo.length > 0) {
      const consulenteId = sessionInfo[0].consulente_id;
      
      // Atualizar ou criar registo de presença
      const [existingAttendance] = await pool.execute(
        'SELECT id FROM attendance_records WHERE consulente_id = ? AND attendance_date = ?',
        [consulenteId, sessionDate]
      );
      
      if (existingAttendance.length > 0) {
        // Atualizar registo existente
        await pool.execute(`
          UPDATE attendance_records 
          SET status = 'pending', notes = ?, updated_at = NOW()
          WHERE consulente_id = ? AND attendance_date = ?
        `, [
          `Presença automática (Pendente) - Sessão: ${description.trim()}`,
          consulenteId,
          sessionDate
        ]);
      } else {
        // Criar novo registo
        await pool.execute(`
          INSERT INTO attendance_records (consulente_id, attendance_date, status, notes, created_at)
          VALUES (?, ?, 'pending', ?, NOW())
        `, [
          consulenteId,
          sessionDate,
          `Presença automática (Pendente) - Sessão: ${description.trim()}`
        ]);
      }
    }
    
    // Buscar a sessão atualizada
    const [updatedSession] = await pool.execute(`
      SELECT 
        id,
        consulente_id,
        CONVERT_TZ(session_date, '+00:00', '+01:00') as session_date,
        description,
        notes,
        acompanhantes_ids,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulente_sessions WHERE id = ?
    `, [id]);
    
    res.json(updatedSession[0]);
  } catch (error) {
    console.error('Erro ao atualizar sessão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/consulentes/sessions/:id - Deletar sessão
router.delete('/sessions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se a sessão existe
    const [existing] = await pool.execute(
      'SELECT id FROM consulente_sessions WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Sessão não encontrada' });
    }
    
    // Buscar informações da sessão antes de deletar
    const [sessionInfo] = await pool.execute(`
      SELECT consulente_id, session_date 
      FROM consulente_sessions 
      WHERE id = ?
    `, [id]);
    
    if (sessionInfo.length === 0) {
      return res.status(404).json({ error: 'Sessão não encontrada' });
    }
    
    const consulenteId = sessionInfo[0].consulente_id;
    const sessionDate = new Date(sessionInfo[0].session_date).toISOString().split('T')[0];
    
    // Deletar a sessão
    const [result] = await pool.execute(
      'DELETE FROM consulente_sessions WHERE id = ?',
      [id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Sessão não encontrada' });
    }
    
    // Verificar se existem outras sessões para este consulente nesta data
    const [otherSessions] = await pool.execute(`
      SELECT COUNT(*) as count 
      FROM consulente_sessions 
      WHERE consulente_id = ? AND DATE(session_date) = ?
    `, [consulenteId, sessionDate]);
    
    // Se não houver outras sessões nesta data, remover o registo de presença automática
    if (otherSessions[0].count === 0) {
      await pool.execute(`
        DELETE FROM attendance_records 
        WHERE consulente_id = ? AND attendance_date = ? AND notes LIKE 'Presença automática (Pendente)%'
      `, [consulenteId, sessionDate]);
    }
    
    res.json({ message: 'Sessão deletada com sucesso' });
  } catch (error) {
    console.error('Erro ao deletar sessão:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/consulentes/sessions-by-date/:date - Buscar sessões por data (incluindo acompanhantes)
router.get('/sessions-by-date/:date', async (req, res) => {
  try {
    const { date } = req.params;
    
    console.log(`=== DEBUG API SESSIONS BY DATE ===`);
    console.log(`Buscando sessões para data: ${date}`);
    
    const [sessions] = await pool.execute(`
      SELECT 
        id,
        consulente_id,
        CONVERT_TZ(session_date, '+00:00', '+01:00') as session_date,
        description,
        notes,
        acompanhantes_ids,
        CONVERT_TZ(created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(updated_at, '+00:00', '+01:00') as updated_at
      FROM consulente_sessions 
      WHERE DATE(session_date) = ?
      ORDER BY session_date ASC
    `, [date]);
    
    console.log(`Sessões encontradas: ${sessions.length}`);
    sessions.forEach(session => {
      console.log(`Sessão ${session.id}: Consulente ${session.consulente_id}, Acompanhantes: ${session.acompanhantes_ids}`);
    });
    console.log(`=== FIM DEBUG API SESSIONS BY DATE ===`);
    
    res.json(sessions);
  } catch (error) {
    console.error('Erro ao buscar sessões por data:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router;
