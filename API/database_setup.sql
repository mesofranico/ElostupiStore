-- Script para criar as tabelas de membros e pagamentos
-- Execute este script no seu banco de dados MySQL

USE elostupistore;

-- Tabela de membros da corrente mediúnica
CREATE TABLE IF NOT EXISTS members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    membership_type ENUM('Mensal', 'Trimestral', 'Semestral', 'Anual') DEFAULT 'Mensal',
    monthly_fee DECIMAL(10,2) NOT NULL,
    join_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_payment_date DATE NULL,
    next_payment_date DATE NULL,
    payment_status ENUM('pending', 'paid', 'overdue', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name),
    INDEX idx_email (email),
    INDEX idx_payment_status (payment_status),
    INDEX idx_next_payment_date (next_payment_date),
    INDEX idx_is_active (is_active)
);

-- Tabela de pagamentos
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    INDEX idx_member_id (member_id),
    INDEX idx_payment_date (payment_date),
    INDEX idx_status (status)
);

-- Inserir exemplos de cada tipo de mensalidade
INSERT INTO members (name, email, phone, membership_type, monthly_fee, join_date, is_active, payment_status) VALUES
('João Silva', 'joao.silva@email.com', '(351) 999999111', 'Mensal', 25.00, '2025-01-15', TRUE, 'paid'),
('Maria Santos', 'maria.santos@email.com', '(351) 999999222', 'Trimestral', 70.00, '2025-02-01', TRUE, 'pending'),
('Ana Costa', 'ana.costa@email.com', '(351) 999999444', 'Semestral', 135.00, '2025-03-01', TRUE, 'paid'),
('Carlos Ferreira', 'carlos.ferreira@email.com', '(351) 999999555', 'Anual', 250.00, '2025-01-10', TRUE, 'paid');

-- Inserir pagamentos de exemplo para cada tipo
INSERT INTO payments (member_id, amount, payment_date, status) VALUES
(1, 25.00, '2025-02-01', 'completed'),
(1, 25.00, '2025-03-01', 'completed'),
(2, 70.00, '2025-02-01', 'completed'),
(3, 135.00, '2025-03-01', 'completed'),
(4, 250.00, '2025-01-10', 'completed');

-- Atualizar dados dos membros com base nos pagamentos
UPDATE members SET 
    last_payment_date = '2025-03-01',
    next_payment_date = '2025-04-01',
    payment_status = 'paid'
WHERE id = 1;

UPDATE members SET 
    last_payment_date = '2025-02-01',
    next_payment_date = '2025-05-01',
    payment_status = 'paid'
WHERE id = 2;

UPDATE members SET 
    last_payment_date = '2025-03-01',
    next_payment_date = '2025-09-01',
    payment_status = 'paid'
WHERE id = 3;

UPDATE members SET 
    last_payment_date = '2025-01-10',
    next_payment_date = '2026-01-10',
    payment_status = 'paid'
WHERE id = 4;

-- Criar view para membros em atraso
CREATE OR REPLACE VIEW overdue_members AS
SELECT 
    m.*,
    DATEDIFF(CURDATE(), m.next_payment_date) as days_overdue
FROM members m
WHERE m.is_active = 1 
    AND (m.next_payment_date < CURDATE() OR m.payment_status = 'overdue')
ORDER BY m.next_payment_date ASC;

-- Criar view para relatório de pagamentos
CREATE OR REPLACE VIEW payment_summary AS
SELECT 
    DATE_FORMAT(p.payment_date, '%Y-%m') as month,
    COUNT(*) as total_payments,
    SUM(p.amount) as total_amount,
    AVG(p.amount) as average_amount,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) as completed_payments,
    COUNT(CASE WHEN p.status = 'pending' THEN 1 END) as pending_payments,
    COUNT(CASE WHEN p.status = 'failed' THEN 1 END) as failed_payments
FROM payments p
GROUP BY DATE_FORMAT(p.payment_date, '%Y-%m')
ORDER BY month DESC;

-- Criar procedimento para atualizar status de pagamentos em atraso
DELIMITER //
CREATE PROCEDURE UpdateOverduePayments()
BEGIN
    UPDATE members 
    SET payment_status = 'overdue'
    WHERE is_active = 1 
        AND next_payment_date < CURDATE() 
        AND payment_status = 'pending';
END //
DELIMITER ;

-- Criar evento para executar o procedimento diariamente
CREATE EVENT IF NOT EXISTS daily_overdue_check
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO CALL UpdateOverduePayments();

-- Mostrar as tabelas criadas
SHOW TABLES;

-- Mostrar dados de exemplo
SELECT * FROM members;
SELECT * FROM payments; 