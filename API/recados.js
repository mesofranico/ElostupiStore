const express = require('express');
const router = express.Router();
const pool = require('./db');

// Helper function to resolve consulente names for a list of recados
async function resolveConsulenteNames(recados) {
    const allIds = new Set();
    recados.forEach(r => {
        let ids = [];
        if (r.consulente_ids) {
            try {
                ids = JSON.parse(r.consulente_ids);
            } catch (e) {
                // Backward compatibility if it was a single ID
                if (!isNaN(r.consulente_ids)) ids = [parseInt(r.consulente_ids)];
            }
        } else if (r.consulente_id) {
            ids = [r.consulente_id];
        }
        r.consulenteIds = ids;
        ids.forEach(id => allIds.add(id));
    });

    if (allIds.size === 0) {
        recados.forEach(r => r.consulenteNames = []);
        return recados;
    }

    const [consulentes] = await pool.execute(
        `SELECT id, name FROM consulentes WHERE id IN (${Array.from(allIds).join(',')})`
    );

    const nameMap = {};
    consulentes.forEach(c => nameMap[c.id] = c.name);

    recados.forEach(r => {
        r.consulenteNames = r.consulenteIds.map(id => nameMap[id] || 'N/A');
    });

    return recados;
}

// Buscar todos os recados
router.get('/', async (req, res) => {
    try {
        const [rows] = await pool.execute(`
      SELECT 
        id,
        titulo,
        pessoa,
        instrucao,
        CONVERT_TZ(data_limite, '+00:00', '+01:00') as dataLimite,
        alerta,
        consulente_ids,
        created_at,
        updated_at
      FROM recados 
      ORDER BY created_at DESC
    `);

        const resolved = await resolveConsulenteNames(rows);

        // Converter alerta para boolean
        const formattedRows = resolved.map(row => ({
            ...row,
            alerta: row.alerta === 1,
            created_at: row.created_at,
            updated_at: row.updated_at
        }));

        res.json(formattedRows);
    } catch (error) {
        console.error('Erro ao buscar recados:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// Adicionar novo recado
router.post('/', async (req, res) => {
    try {
        const { titulo, pessoa, instrucao, dataLimite, alerta, consulenteIds } = req.body;

        if (!titulo) {
            return res.status(400).json({ error: 'Título é obrigatório' });
        }

        const idsJson = consulenteIds ? JSON.stringify(consulenteIds) : null;

        const [result] = await pool.execute(
            'INSERT INTO recados (titulo, pessoa, instrucao, data_limite, alerta, consulente_ids, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
            [titulo, pessoa || '', instrucao || '', dataLimite || null, alerta ? 1 : 0, idsJson]
        );

        const [rows] = await pool.execute('SELECT * FROM recados WHERE id = ?', [result.insertId]);
        const resolved = await resolveConsulenteNames(rows);

        const newRecado = {
            ...resolved[0],
            alerta: resolved[0].alerta === 1,
            dataLimite: resolved[0].data_limite
        };

        res.status(201).json(newRecado);
    } catch (error) {
        console.error('Erro ao adicionar recado:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// Atualizar recado
router.put('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { titulo, pessoa, instrucao, dataLimite, alerta, consulenteIds } = req.body;

        const idsJson = consulenteIds ? JSON.stringify(consulenteIds) : null;

        await pool.execute(
            'UPDATE recados SET titulo = ?, pessoa = ?, instrucao = ?, data_limite = ?, alerta = ?, consulente_ids = ? WHERE id = ?',
            [titulo, pessoa || '', instrucao || '', dataLimite || null, alerta ? 1 : 0, idsJson, id]
        );

        const [rows] = await pool.execute('SELECT * FROM recados WHERE id = ?', [id]);
        if (rows.length === 0) {
            return res.status(404).json({ error: 'Recado não encontrado' });
        }

        const resolved = await resolveConsulenteNames(rows);

        const updatedRecado = {
            ...resolved[0],
            alerta: resolved[0].alerta === 1,
            dataLimite: resolved[0].data_limite
        };

        res.json(updatedRecado);
    } catch (error) {
        console.error('Erro ao atualizar recado:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

// Eliminar recado
router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        await pool.execute('DELETE FROM recados WHERE id = ?', [id]);
        res.json({ message: 'Recado eliminado com sucesso' });
    } catch (error) {
        console.error('Erro ao eliminar recado:', error);
        res.status(500).json({ error: 'Erro interno do servidor' });
    }
});

module.exports = router;
