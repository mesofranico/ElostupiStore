-- =============================================================================
-- SCRIPT COMPLETO DE CONFIGURAÇÃO DA BASE DE DADOS - SISTEMA DE GIRAS
-- =============================================================================
-- Este script cria todas as tabelas, views, procedures e eventos necessários
-- para o sistema de Giras de Umbanda com participações
-- Execute este script no seu banco de dados MySQL
-- =============================================================================

USE elostupistore;

-- =============================================================================
-- 1. TABELA DE GIRAS DE UMBANDA
-- =============================================================================

-- Tabela principal das Giras
CREATE TABLE IF NOT EXISTS giras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    orixa_name VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    description TEXT,
    is_past BOOLEAN DEFAULT FALSE,
    max_participants INT DEFAULT 0,
    current_participants INT DEFAULT 0,
    status ENUM('active', 'cancelled', 'postponed') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_title (title),
    INDEX idx_orixa_name (orixa_name),
    INDEX idx_date (date),
    INDEX idx_is_past (is_past),
    INDEX idx_status (status),
    INDEX idx_date_time (date, time)
);

-- =============================================================================
-- 2. TABELA DE PARTICIPANTES DAS GIRAS
-- =============================================================================

-- Tabela de participantes (depende da tabela giras)
CREATE TABLE IF NOT EXISTS gira_participants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gira_id INT NOT NULL,
    participant_name VARCHAR(255) NOT NULL,
    participant_email VARCHAR(255) NOT NULL,
    participant_phone VARCHAR(20),
    companions INT DEFAULT 0,
    notes TEXT,
    status ENUM('confirmed', 'pending', 'cancelled') DEFAULT 'confirmed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (gira_id) REFERENCES giras(id) ON DELETE CASCADE,
    UNIQUE KEY unique_participant_gira (gira_id, participant_email),
    INDEX idx_gira_id (gira_id),
    INDEX idx_participant_email (participant_email),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_companions (companions)
);

-- =============================================================================
-- 3. TABELA DE PAGAMENTOS (se não existir)
-- =============================================================================

-- Tabela de pagamentos (depende da tabela members)
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME NOT NULL,
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
    payment_type ENUM('regular', 'extra', 'late_fee') DEFAULT 'regular',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE,
    INDEX idx_member_id (member_id),
    INDEX idx_payment_date (payment_date),
    INDEX idx_status (status),
    INDEX idx_payment_type (payment_type)
);

-- =============================================================================
-- 4. DADOS DE EXEMPLO
-- =============================================================================

-- Inserir Giras de exemplo (apenas se não existirem)
INSERT IGNORE INTO giras (id, title, orixa_name, date, time, description, is_past, max_participants, current_participants, status) VALUES
(1, 'Gira de Oxalá', 'Oxalá', '2024-12-15', '20:00:00', 'Cerimónia espiritual dedicada ao Orixá Oxalá, pai de todos os Orixás. Traz paz, harmonia e sabedoria.', 1, 50, 0, 'active'),
(2, 'Gira de Xangô', 'Xangô', '2024-12-18', '20:00:00', 'Gira dedicada ao Orixá Xangô, senhor da justiça e da força. Traz proteção e equilíbrio.', 1, 50, 0, 'active'),
(3, 'Gira de Iemanjá', 'Iemanjá', '2024-12-22', '20:00:00', 'Cerimónia em honra da Mãe Iemanjá, rainha dos mares. Traz amor maternal e proteção familiar.', 1, 50, 0, 'active'),
(4, 'Gira de Ogum', 'Ogum', '2024-12-28', '20:00:00', 'Gira dedicada ao Orixá Ogum, guerreiro e protetor. Traz coragem, força e determinação.', 0, 50, 0, 'active'),
(5, 'Gira de Oxóssi', 'Oxóssi', '2025-01-05', '20:00:00', 'Cerimónia dedicada ao Orixá Oxóssi, caçador e protetor da natureza. Traz abundância e prosperidade.', 0, 50, 0, 'active'),
(6, 'Gira de Iansã', 'Iansã', '2025-01-12', '20:00:00', 'Gira em honra da Orixá Iansã, senhora dos ventos e tempestades. Traz transformação e renovação.', 0, 50, 0, 'active');

-- Inserir participantes de exemplo (apenas se não existirem)
INSERT IGNORE INTO gira_participants (id, gira_id, participant_name, participant_email, participant_phone, companions, notes, status) VALUES
(1, 1, 'Maria Silva', 'maria.silva@email.com', '(351) 999999111', 2, 'Primeira vez a participar', 'confirmed'),
(2, 1, 'João Santos', 'joao.santos@email.com', '(351) 999999222', 0, 'Participante regular', 'confirmed'),
(3, 1, 'Ana Costa', 'ana.costa@email.com', '(351) 999999333', 1, NULL, 'confirmed'),
(4, 2, 'Carlos Ferreira', 'carlos.ferreira@email.com', '(351) 999999444', 0, 'Interessado em Xangô', 'confirmed'),
(5, 2, 'Sofia Martins', 'sofia.martins@email.com', '(351) 999999555', 3, NULL, 'confirmed'),
(6, 3, 'Pedro Oliveira', 'pedro.oliveira@email.com', '(351) 999999666', 1, 'Adora Iemanjá', 'confirmed'),
(7, 4, 'Isabel Rodrigues', 'isabel.rodrigues@email.com', '(351) 999999777', 0, 'Primeira gira de Ogum', 'confirmed'),
(8, 4, 'Miguel Alves', 'miguel.alves@email.com', '(351) 999999888', 2, NULL, 'confirmed'),
(9, 5, 'Teresa Sousa', 'teresa.sousa@email.com', '(351) 999999999', 0, 'Interessada em Oxóssi', 'confirmed'),
(10, 6, 'António Lima', 'antonio.lima@email.com', '(351) 999999000', 1, 'Primeira vez', 'confirmed');

-- =============================================================================
-- 5. VIEWS PARA CONSULTAS OTIMIZADAS
-- =============================================================================

-- View para Giras ativas
CREATE OR REPLACE VIEW active_giras AS
SELECT 
    id,
    title,
    orixa_name,
    date,
    time,
    description,
    image_url,
    max_participants,
    current_participants,
    status,
    created_at,
    updated_at
FROM giras 
WHERE is_past = 0 AND status = 'active'
ORDER BY date ASC, time ASC;

-- View para Giras passadas
CREATE OR REPLACE VIEW past_giras AS
SELECT 
    id,
    title,
    orixa_name,
    date,
    time,
    description,
    image_url,
    max_participants,
    current_participants,
    status,
    created_at,
    updated_at
FROM giras 
WHERE is_past = 1
ORDER BY date DESC, time DESC;

-- View para estatísticas das Giras
CREATE OR REPLACE VIEW giras_stats AS
SELECT 
    COUNT(*) as total_giras,
    COUNT(CASE WHEN is_past = 0 THEN 1 END) as active_giras,
    COUNT(CASE WHEN is_past = 1 THEN 1 END) as past_giras,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_status,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_status,
    COUNT(CASE WHEN status = 'postponed' THEN 1 END) as postponed_status,
    SUM(current_participants) as total_participants,
    AVG(current_participants) as avg_participants_per_gira
FROM giras;

-- View para estatísticas de participação
CREATE OR REPLACE VIEW participation_stats AS
SELECT 
    g.id as gira_id,
    g.title as gira_title,
    g.orixa_name,
    g.date,
    g.max_participants,
    g.current_participants,
    CASE 
        WHEN g.max_participants > 0 THEN 
            ROUND((g.current_participants / g.max_participants) * 100, 1)
        ELSE 0 
    END as participation_percentage,
    CASE 
        WHEN g.max_participants > 0 AND g.current_participants >= g.max_participants THEN 'Lotada'
        WHEN g.max_participants > 0 AND g.current_participants >= (g.max_participants * 0.8) THEN 'Quase Lotada'
        WHEN g.max_participants > 0 AND g.current_participants >= (g.max_participants * 0.5) THEN 'Meio Cheia'
        WHEN g.max_participants > 0 AND g.current_participants > 0 THEN 'Poucos Participantes'
        ELSE 'Sem Participantes'
    END as capacity_status
FROM giras g
ORDER BY g.date ASC;

-- =============================================================================
-- 6. STORED PROCEDURES
-- =============================================================================

-- Remover procedures existentes para evitar conflitos
DROP PROCEDURE IF EXISTS UpdatePastGiras;
DROP PROCEDURE IF EXISTS UpdateGiraParticipantCounts;

DELIMITER //

-- Procedure para atualizar status de Giras passadas
CREATE PROCEDURE UpdatePastGiras()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    UPDATE giras 
    SET is_past = 1
    WHERE date < CURDATE() AND is_past = 0;
    
    COMMIT;
    
    SELECT CONCAT('Atualizadas ', ROW_COUNT(), ' giras para status passado') as resultado;
END //

-- Procedure para atualizar contadores de participantes
CREATE PROCEDURE UpdateGiraParticipantCounts()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    UPDATE giras g 
    SET current_participants = (
        SELECT COUNT(*) 
        FROM gira_participants gp 
        WHERE gp.gira_id = g.id AND gp.status = 'confirmed'
    );
    
    COMMIT;
    
    SELECT CONCAT('Atualizados contadores de ', ROW_COUNT(), ' giras') as resultado;
END //

DELIMITER ;

-- =============================================================================
-- 7. EVENTOS AUTOMÁTICOS
-- =============================================================================

-- Remover eventos existentes para evitar conflitos
DROP EVENT IF EXISTS daily_giras_check;
DROP EVENT IF EXISTS daily_participant_count_update;

DELIMITER //

-- Evento para atualizar status de Giras passadas diariamente
CREATE EVENT daily_giras_check
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Atualiza diariamente o status das Giras passadas'
DO
BEGIN
    CALL UpdatePastGiras();
END //

-- Evento para atualizar contadores de participantes diariamente
CREATE EVENT daily_participant_count_update
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Atualiza diariamente os contadores de participantes das Giras'
DO
BEGIN
    CALL UpdateGiraParticipantCounts();
END //

DELIMITER ;

-- =============================================================================
-- 8. ATUALIZAÇÃO INICIAL DOS DADOS
-- =============================================================================

-- Atualizar contadores de participantes nas Giras existentes
CALL UpdateGiraParticipantCounts();

-- Atualizar status de Giras passadas
CALL UpdatePastGiras();

-- =============================================================================
-- 9. VERIFICAÇÕES E RELATÓRIOS FINAIS
-- =============================================================================

-- Verificar se o Event Scheduler está ativo
SELECT 'Status do Event Scheduler:' as info;
SHOW VARIABLES LIKE 'event_scheduler';

-- Mostrar tabelas criadas
SELECT 'Tabelas criadas:' as info;
SHOW TABLES WHERE Tables_in_elostupistore IN ('giras', 'gira_participants');

-- Mostrar views criadas
SELECT 'Views criadas:' as info;
SHOW FULL TABLES WHERE Table_type = 'VIEW' AND Tables_in_elostupistore LIKE '%giras%';

-- Mostrar procedures criadas
SELECT 'Procedures criadas:' as info;
SHOW PROCEDURE STATUS WHERE Db = 'elostupistore' AND Name IN ('UpdatePastGiras', 'UpdateGiraParticipantCounts');

-- Mostrar eventos criados
SELECT 'Eventos criados:' as info;
SHOW EVENTS WHERE Db = 'elostupistore' AND Name IN ('daily_giras_check', 'daily_participant_count_update');

-- Relatório final das Giras
SELECT 'Relatório das Giras:' as info;
SELECT 
    id,
    title,
    orixa_name,
    date,
    time,
    max_participants,
    current_participants,
    CASE 
        WHEN max_participants > 0 THEN 
            CONCAT(ROUND((current_participants / max_participants) * 100, 1), '%')
        ELSE 'N/A'
    END as capacity_percentage,
    status,
    CASE WHEN is_past = 1 THEN 'Passada' ELSE 'Futura' END as timing_status
FROM giras 
ORDER BY date ASC;

-- Relatório dos participantes
SELECT 'Relatório dos Participantes:' as info;
SELECT 
    gp.id,
    g.title as gira,
    gp.participant_name,
    gp.participant_email,
    gp.companions,
    gp.status,
    gp.created_at
FROM gira_participants gp
JOIN giras g ON gp.gira_id = g.id
ORDER BY g.date ASC, gp.created_at ASC;

-- Estatísticas gerais
SELECT 'Estatísticas Gerais:' as info;
SELECT * FROM giras_stats;

SELECT 'Estatísticas de Participação:' as info;
SELECT * FROM participation_stats;

-- =============================================================================
-- CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!
-- =============================================================================
-- 
-- O sistema está agora completamente configurado com:
-- ✅ Tabelas: giras, gira_participants, payments
-- ✅ Views: active_giras, past_giras, giras_stats, participation_stats
-- ✅ Procedures: UpdatePastGiras, UpdateGiraParticipantCounts
-- ✅ Eventos: daily_giras_check, daily_participant_count_update
-- ✅ Dados de exemplo para teste
-- ✅ Relatórios de verificação
--
-- NOTA: Se o Event Scheduler mostrar 'OFF', execute:
-- SET GLOBAL event_scheduler = ON;
--
-- =============================================================================