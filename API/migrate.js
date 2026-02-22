const pool = require('./db');
const fs = require('fs');
const path = require('path');

async function migrate() {
    try {
        console.log('Criando tabela settings se não existir...');
        await pool.query(`
      CREATE TABLE IF NOT EXISTS settings (
        setting_key VARCHAR(50) PRIMARY KEY,
        setting_value VARCHAR(255) NOT NULL,
        description VARCHAR(255),
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

        console.log('Inserindo ou ignorando attendance_fee...');
        await pool.query(`
      INSERT IGNORE INTO settings (setting_key, setting_value, description) 
      VALUES ('attendance_fee', '3.50', 'Valor padrão pago por cada consulente na sessão');
    `);

        console.log('Migração concluída com sucesso.');
    } catch (error) {
        console.error('Erro na migração:', error);
    } finally {
        process.exit();
    }
}

migrate();
