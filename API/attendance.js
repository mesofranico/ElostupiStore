const express = require('express');
const router = express.Router();
const pool = require('./db');

// GET /api/attendance - Buscar registos de presença por data
router.get('/', async (req, res) => {
  try {
    const { date } = req.query;
    
    if (!date) {
      return res.status(400).json({ error: 'Data é obrigatória' });
    }
    
    const [rows] = await pool.execute(`
      SELECT 
        ar.id,
        ar.consulente_id,
        ar.attendance_date,
        ar.status,
        ar.notes,
        CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at,
        c.name as consulente_name,
        c.phone as consulente_phone,
        c.email as consulente_email
      FROM attendance_records ar
      JOIN consulentes c ON ar.consulente_id = c.id
      WHERE ar.attendance_date = ?
      ORDER BY c.name ASC
    `, [date]);
    
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar registos de presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/attendance/date/:date - Buscar registos de presença por data específica
router.get('/date/:date', async (req, res) => {
  try {
    const { date } = req.params;
    
    const [rows] = await pool.execute(`
      SELECT 
        ar.id,
        ar.consulente_id,
        ar.attendance_date,
        ar.status,
        ar.notes,
        CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at,
        c.name as consulente_name,
        c.phone as consulente_phone,
        c.email as consulente_email
      FROM attendance_records ar
      JOIN consulentes c ON ar.consulente_id = c.id
      WHERE ar.attendance_date = ?
      ORDER BY c.name ASC
    `, [date]);
    
    res.json(rows);
  } catch (error) {
    console.error('Erro ao buscar registos de presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/attendance - Criar/atualizar registo de presença
router.post('/', async (req, res) => {
  try {
    const { consulente_id, attendance_date, status, notes } = req.body;
    
    // Validações básicas
    if (!consulente_id || !attendance_date || !status) {
      return res.status(400).json({ error: 'ID do consulente, data e status são obrigatórios' });
    }
    
    if (!['present', 'absent', 'pending'].includes(status)) {
      return res.status(400).json({ error: 'Status deve ser present, absent ou pending' });
    }
    
    // Verificar se já existe registo para este consulente nesta data
    const [existing] = await pool.execute(
      'SELECT id FROM attendance_records WHERE consulente_id = ? AND attendance_date = ?',
      [consulente_id, attendance_date]
    );
    
    if (existing.length > 0) {
      // Atualizar registo existente
      await pool.execute(`
        UPDATE attendance_records 
        SET status = ?, notes = ?, updated_at = NOW()
        WHERE consulente_id = ? AND attendance_date = ?
      `, [status, notes || null, consulente_id, attendance_date]);
      
      const [updated] = await pool.execute(`
        SELECT 
          ar.id,
          ar.consulente_id,
          ar.attendance_date,
          ar.status,
          ar.notes,
          CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
          CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at,
          c.name as consulente_name,
          c.phone as consulente_phone,
          c.email as consulente_email
        FROM attendance_records ar
        JOIN consulentes c ON ar.consulente_id = c.id
        WHERE ar.consulente_id = ? AND ar.attendance_date = ?
      `, [consulente_id, attendance_date]);
      
      res.json(updated[0]);
    } else {
      // Criar novo registo
      const [result] = await pool.execute(`
        INSERT INTO attendance_records (consulente_id, attendance_date, status, notes, created_at)
        VALUES (?, ?, ?, ?, NOW())
      `, [consulente_id, attendance_date, status, notes || null]);
      
      const [newRecord] = await pool.execute(`
        SELECT 
          ar.id,
          ar.consulente_id,
          ar.attendance_date,
          ar.status,
          ar.notes,
          CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
          CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at,
          c.name as consulente_name,
          c.phone as consulente_phone,
          c.email as consulente_email
        FROM attendance_records ar
        JOIN consulentes c ON ar.consulente_id = c.id
        WHERE ar.id = ?
      `, [result.insertId]);
      
      res.status(201).json(newRecord[0]);
    }
  } catch (error) {
    console.error('Erro ao criar/atualizar registo de presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// PUT /api/attendance/:id - Atualizar registo de presença
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    
    // Verificar se o registo existe
    const [existing] = await pool.execute(
      'SELECT id FROM attendance_records WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Registo de presença não encontrado' });
    }
    
    // Validações básicas
    if (!status || !['present', 'absent', 'pending'].includes(status)) {
      return res.status(400).json({ error: 'Status deve ser present, absent ou pending' });
    }
    
    await pool.execute(`
      UPDATE attendance_records 
      SET status = ?, notes = ?, updated_at = NOW()
      WHERE id = ?
    `, [status, notes || null, id]);
    
    const [updated] = await pool.execute(`
      SELECT 
        ar.id,
        ar.consulente_id,
        ar.attendance_date,
        ar.status,
        ar.notes,
        CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at,
        c.name as consulente_name,
        c.phone as consulente_phone,
        c.email as consulente_email
      FROM attendance_records ar
      JOIN consulentes c ON ar.consulente_id = c.id
      WHERE ar.id = ?
    `, [id]);
    
    res.json(updated[0]);
  } catch (error) {
    console.error('Erro ao atualizar registo de presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// DELETE /api/attendance/:id - Deletar registo de presença e sessões correspondentes
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Verificar se o registo existe e obter informações
    const [existing] = await pool.execute(
      'SELECT id, consulente_id, attendance_date FROM attendance_records WHERE id = ?',
      [id]
    );
    
    if (existing.length === 0) {
      return res.status(404).json({ error: 'Registo de presença não encontrado' });
    }
    
    const record = existing[0];
    const consulenteId = record.consulente_id;
    const attendanceDate = record.attendance_date;
    
    console.log(`=== DEBUG DELETE ATTENDANCE API ===`);
    console.log(`Eliminando marcação ID: ${id}`);
    console.log(`Consulente ID: ${consulenteId}`);
    console.log(`Data: ${attendanceDate}`);
    
    // Buscar sessões correspondentes para esta data e consulente
    const [sessions] = await pool.execute(`
      SELECT id FROM consulente_sessions 
      WHERE consulente_id = ? AND DATE(session_date) = ?
    `, [consulenteId, attendanceDate]);
    
    console.log(`Sessões encontradas para eliminar: ${sessions.length}`);
    
    // Eliminar as sessões correspondentes primeiro
    for (const session of sessions) {
      console.log(`Eliminando sessão ID: ${session.id} do histórico`);
      await pool.execute(
        'DELETE FROM consulente_sessions WHERE id = ?',
        [session.id]
      );
    }
    
    // Deletar o registo de presença
    const [result] = await pool.execute(
      'DELETE FROM attendance_records WHERE id = ?',
      [id]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Registo de presença não encontrado' });
    }
    
    console.log(`Marcação e ${sessions.length} sessões eliminadas com sucesso`);
    console.log(`=== FIM DEBUG DELETE ATTENDANCE API ===`);
    
    res.json({ 
      message: 'Registo de presença e sessões correspondentes deletados com sucesso',
      deletedSessions: sessions.length
    });
  } catch (error) {
    console.error('Erro ao deletar registo de presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/attendance/consulente/:id - Buscar histórico de presenças de um consulente
router.get('/consulente/:id', async (req, res) => {
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
    
    // Buscar registos de presença do consulente
    const [records] = await pool.execute(`
      SELECT 
        ar.id,
        ar.consulente_id,
        ar.attendance_date,
        ar.status,
        ar.notes,
        CONVERT_TZ(ar.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(ar.updated_at, '+00:00', '+01:00') as updated_at
      FROM attendance_records ar
      WHERE ar.consulente_id = ?
      ORDER BY ar.attendance_date DESC
    `, [id]);
    
    res.json({ 
      consulente: consulente[0].name,
      records: records,
      total: records.length
    });
  } catch (error) {
    console.error('Erro ao buscar histórico de presenças:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/attendance/stats/:date - Obter estatísticas de presença por data
router.get('/stats/:date', async (req, res) => {
  try {
    const { date } = req.params;
    
    const [stats] = await pool.execute(`
      SELECT 
        COUNT(*) as total_records,
        COUNT(CASE WHEN status = 'present' THEN 1 END) as presentes,
        COUNT(CASE WHEN status = 'absent' THEN 1 END) as faltas,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pendentes
      FROM attendance_records 
      WHERE attendance_date = ?
    `, [date]);
    
    res.json(stats[0]);
  } catch (error) {
    console.error('Erro ao buscar estatísticas:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// POST /api/attendance/bulk - Criar registos em massa para uma data
router.post('/bulk', async (req, res) => {
  try {
    const { attendance_date, consulente_ids } = req.body;
    
    if (!attendance_date || !Array.isArray(consulente_ids)) {
      return res.status(400).json({ error: 'Data e lista de IDs de consulentes são obrigatórios' });
    }
    
    // Iniciar transação
    await pool.execute('START TRANSACTION');
    
    try {
      const results = [];
      
      for (const consulente_id of consulente_ids) {
        // Verificar se já existe registo
        const [existing] = await pool.execute(
          'SELECT id FROM attendance_records WHERE consulente_id = ? AND attendance_date = ?',
          [consulente_id, attendance_date]
        );
        
        if (existing.length === 0) {
          // Criar novo registo com status pending
          const [result] = await pool.execute(`
            INSERT INTO attendance_records (consulente_id, attendance_date, status, created_at)
            VALUES (?, ?, 'pending', NOW())
          `, [consulente_id, attendance_date]);
          
          results.push({ consulente_id, created: true, id: result.insertId });
        } else {
          results.push({ consulente_id, created: false, id: existing[0].id });
        }
      }
      
      // Confirmar transação
      await pool.execute('COMMIT');
      
      res.json({ 
        message: 'Registos processados com sucesso',
        results: results
      });
      
    } catch (transactionError) {
      // Reverter transação em caso de erro
      await pool.execute('ROLLBACK');
      throw transactionError;
    }
    
  } catch (error) {
    console.error('Erro ao criar registos em massa:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

// GET /api/attendance/consulentes-without/:date - Buscar consulentes sem presença numa data específica
router.get('/consulentes-without/:date', async (req, res) => {
  try {
    const { date } = req.params;
    
    const [consulentes] = await pool.execute(`
      SELECT 
        c.id,
        c.name,
        c.phone,
        c.email,
        c.notes,
        CONVERT_TZ(c.created_at, '+00:00', '+01:00') as created_at,
        CONVERT_TZ(c.updated_at, '+00:00', '+01:00') as updated_at
      FROM consulentes c
      LEFT JOIN attendance_records ar ON c.id = ar.consulente_id AND ar.attendance_date = ?
      WHERE ar.id IS NULL
      ORDER BY c.name ASC
    `, [date]);
    
    res.json(consulentes);
  } catch (error) {
    console.error('Erro ao buscar consulentes sem presença:', error);
    res.status(500).json({ error: 'Erro interno do servidor' });
  }
});

module.exports = router;
