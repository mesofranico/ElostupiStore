<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

$message = '';
$messageType = '';

// Processar mensagens de redirecionamento
if (isset($_GET['message'])) {
    $message = $_GET['message'];
    $messageType = $_GET['type'] ?? 'info';
}

// Buscar todos os consulentes
try {
    $stmt = $pdo->query("
        SELECT 
            id,
            name,
            phone,
            email,
            notes,
            created_at,
            updated_at
        FROM consulentes 
        ORDER BY name ASC
    ");
    $consulentes = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    $message = 'Erro ao carregar consulentes: ' . $e->getMessage();
    $messageType = 'error';
    $consulentes = [];
}

// Buscar estatísticas
try {
    $statsStmt = $pdo->query("
        SELECT 
            COUNT(*) as total_consulentes,
            COUNT(CASE WHEN id IN (SELECT DISTINCT consulente_id FROM consulente_sessions) THEN 1 END) as consulentes_com_sessoes,
            COUNT(CASE WHEN created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) THEN 1 END) as consulentes_recentes
        FROM consulentes
    ");
    $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    $stats = ['total_consulentes' => 0, 'consulentes_com_sessoes' => 0, 'consulentes_recentes' => 0];
}
?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ElosTupi - Gestão de Consulentes</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }

        .header p {
            font-size: 1.1rem;
            opacity: 0.9;
        }

        .content {
            padding: 30px;
        }

        .message {
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 30px;
            font-weight: 500;
        }

        .message.success {
            background: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
        }

        .message.error {
            background: #fef2f2;
            color: #dc2626;
            border: 1px solid #fecaca;
        }

        .message.info {
            background: #dbeafe;
            color: #1e40af;
            border: 1px solid #bfdbfe;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: #f0fdf4;
            border: 2px solid #bbf7d0;
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }

        .stat-card h3 {
            color: #166534;
            font-size: 2rem;
            margin-bottom: 8px;
        }

        .stat-card p {
            color: #15803d;
            font-weight: 500;
        }

        .actions {
            display: flex;
            gap: 15px;
            margin-bottom: 30px;
            flex-wrap: wrap;
        }

        .btn {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 10px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
        }

        .btn-secondary:hover {
            box-shadow: 0 10px 20px rgba(107, 114, 128, 0.3);
        }

        .consulentes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }

        .consulente-card {
            background: white;
            border: 2px solid #e5e7eb;
            border-radius: 12px;
            padding: 20px;
            transition: all 0.3s ease;
            position: relative;
        }

        .consulente-card:hover {
            border-color: #10b981;
            box-shadow: 0 8px 25px rgba(16, 185, 129, 0.15);
            transform: translateY(-2px);
        }

        .consulente-header {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
        }

        .consulente-avatar {
            width: 50px;
            height: 50px;
            background: #d1fae5;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            color: #065f46;
            font-size: 1.2rem;
            margin-right: 15px;
        }

        .consulente-info h3 {
            color: #111827;
            margin-bottom: 5px;
        }

        .consulente-info p {
            color: #6b7280;
            font-size: 0.9rem;
        }

        .consulente-notes {
            background: #f9fafb;
            border-radius: 8px;
            padding: 10px;
            margin-bottom: 15px;
            font-size: 0.9rem;
            color: #374151;
        }

        .consulente-actions {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }

        .btn-small {
            padding: 6px 12px;
            font-size: 0.8rem;
            border-radius: 6px;
        }

        .btn-danger {
            background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        }

        .btn-danger:hover {
            box-shadow: 0 10px 20px rgba(239, 68, 68, 0.3);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6b7280;
        }

        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.5;
        }

        .nav-links {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
        }

        .nav-links a {
            color: #10b981;
            text-decoration: none;
            margin: 0 15px;
            padding: 8px 16px;
            border-radius: 8px;
            transition: all 0.3s ease;
        }

        .nav-links a:hover {
            background: #10b981;
            color: white;
        }

        @media (max-width: 768px) {
            .consulentes-grid {
                grid-template-columns: 1fr;
            }
            
            .actions {
                flex-direction: column;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ElosTupi</h1>
            <p>Gestão de Consulentes</p>
        </div>

        <div class="content">
            <?php if ($message): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <!-- Estatísticas -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3><?php echo $stats['total_consulentes']; ?></h3>
                    <p>Total de Consulentes</p>
                </div>
                <div class="stat-card">
                    <h3><?php echo $stats['consulentes_com_sessoes']; ?></h3>
                    <p>Com Sessões</p>
                </div>
                <div class="stat-card">
                    <h3><?php echo $stats['consulentes_recentes']; ?></h3>
                    <p>Registados Recentemente</p>
                </div>
            </div>

            <!-- Ações -->
            <div class="actions">
                <a href="add_consulente.php" class="btn">
                    <i>➕</i> Novo Consulente
                </a>
                <a href="list_products.php" class="btn btn-secondary">
                    <i>📦</i> Gestão de Produtos
                </a>
                <a href="../" class="btn btn-secondary">
                    <i>🏠</i> Voltar ao App
                </a>
            </div>

            <!-- Lista de Consulentes -->
            <?php if (empty($consulentes)): ?>
                <div class="empty-state">
                    <div style="font-size: 4rem; margin-bottom: 20px; opacity: 0.5;">👥</div>
                    <h3>Nenhum consulente registado</h3>
                    <p>Comece por adicionar o primeiro consulente ao sistema.</p>
                </div>
            <?php else: ?>
                <div class="consulentes-grid">
                    <?php foreach ($consulentes as $consulente): ?>
                        <div class="consulente-card">
                            <div class="consulente-header">
                                <div class="consulente-avatar">
                                    <?php echo strtoupper(substr($consulente['name'], 0, 1)); ?>
                                </div>
                                <div class="consulente-info">
                                    <h3><?php echo htmlspecialchars($consulente['name']); ?></h3>
                                    <p><?php echo htmlspecialchars($consulente['phone']); ?></p>
                                    <?php if (!empty($consulente['email'])): ?>
                                        <p><?php echo htmlspecialchars($consulente['email']); ?></p>
                                    <?php endif; ?>
                                </div>
                            </div>
                            
                            <?php if (!empty($consulente['notes'])): ?>
                                <div class="consulente-notes">
                                    <strong>Notas:</strong><br>
                                    <?php echo htmlspecialchars($consulente['notes']); ?>
                                </div>
                            <?php endif; ?>
                            
                            <div class="consulente-actions">
                                <a href="edit_consulente.php?id=<?php echo $consulente['id']; ?>" class="btn btn-small btn-secondary">
                                    ✏️ Editar
                                </a>
                                <a href="delete_consulente.php?id=<?php echo $consulente['id']; ?>" 
                                   class="btn btn-small btn-danger"
                                   onclick="return confirm('Tem a certeza que deseja eliminar este consulente?')">
                                    🗑️ Eliminar
                                </a>
                            </div>
                        </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>

            <!-- Links de Navegação -->
            <div class="nav-links">
                <a href="add_consulente.php">Adicionar Consulente</a>
                <a href="list_products.php">Gestão de Produtos</a>
                <a href="../">Voltar ao App</a>
                <a href="logout.php" style="color: #dc2626;">Terminar Sessão</a>
            </div>
        </div>
    </div>
</body>
</html>
