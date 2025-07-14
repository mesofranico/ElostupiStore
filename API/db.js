const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: 'localhost',
  user: 'elostore',
  password: 'W#S3j7busb&5Tzzf', // coloque sua senha
  database: 'elostupistore',
  port: 3306,
  waitForConnections: true,
  connectionLimit: 10
});

module.exports = pool; 