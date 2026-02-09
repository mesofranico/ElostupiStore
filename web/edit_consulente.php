<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

$message = '';
$messageType = '';
$consulente = null;

// Verificar se foi fornecido um ID
if (!isset($_GET['id'])) {
    header('Location: list_consulentes.php');
    exit;
}

$consulenteId = $_GET['id'];

// Buscar dados do consulente
try {
    $stmt = $pdo->prepare("SELECT * FROM consulentes WHERE id = ?");
    $stmt->execute([$consulenteId]);
    $consulente = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$consulente) {
        header('Location: list_consulentes.php?message=Consulente não encontrado!&type=error');
        exit;
    }
} catch(PDOException $e) {
    header('Location: list_consulentes.php?message=Erro ao carregar consulente!&type=error');
    exit;
}

// Processar formulário
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Validar dados obrigatórios
        if (empty($_POST['name']) || empty($_POST['phone'])) {
            throw new Exception('Nome e telefone são obrigatórios');
        }

        // Preparar dados
        $name = trim($_POST['name']);
        $phone = trim($_POST['phone']);
        $email = !empty($_POST['email']) ? trim($_POST['email']) : null;
        $notes = !empty($_POST['notes']) ? trim($_POST['notes']) : null;

        // Verificar se já existe outro consulente com este telefone
        $stmt = $pdo->prepare("SELECT id FROM consulentes WHERE phone = ? AND id != ?");
        $stmt->execute([$phone, $consulenteId]);
        
        if ($stmt->fetch()) {
            throw new Exception('Já existe outro consulente com este telefone');
        }

        // Verificar se já existe outro consulente com este email (se fornecido)
        if ($email) {
            $stmt = $pdo->prepare("SELECT id FROM consulentes WHERE email = ? AND id != ?");
            $stmt->execute([$email, $consulenteId]);
            
            if ($stmt->fetch()) {
                throw new Exception('Já existe outro consulente com este email');
            }
        }

        // Atualizar consulente
        $stmt = $pdo->prepare("
            UPDATE consulentes 
            SET name = ?, phone = ?, email = ?, notes = ?, updated_at = NOW()
            WHERE id = ?
        ");
        
        $stmt->execute([$name, $phone, $email, $notes, $consulenteId]);
        
        // Redirecionar para a lista com mensagem de sucesso
        header('Location: list_consulentes.php?message=Consulente atualizado com sucesso!&type=success');
        exit;
        
    } catch (Exception $e) {
        $message = 'Erro: ' . $e->getMessage();
        $messageType = 'error';
    }
}
?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ElosTupi - Editar Consulente</title>
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
            max-width: 600px;
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

        .form-container {
            padding: 40px;
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

        .form-group {
            margin-bottom: 25px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #374151;
            font-size: 0.95rem;
        }

        .required::after {
            content: ' *';
            color: #dc2626;
        }

        input, textarea {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 1rem;
            transition: all 0.3s ease;
            background: #f9fafb;
        }

        input:focus, textarea:focus {
            outline: none;
            border-color: #10b981;
            background: white;
            box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
        }

        textarea {
            resize: vertical;
            min-height: 100px;
        }

        .btn {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            width: 100%;
            margin-top: 10px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(16, 185, 129, 0.3);
        }

        .btn:active {
            transform: translateY(0);
        }

        .help-text {
            font-size: 0.85rem;
            color: #6b7280;
            margin-top: 5px;
        }

        .nav-links {
            text-align: center;
            margin-top: 20px;
        }

        .nav-links a {
            color: #10b981;
            text-decoration: none;
            margin: 0 10px;
            padding: 8px 16px;
            border-radius: 8px;
            transition: all 0.3s ease;
        }

        .nav-links a:hover {
            background: #10b981;
            color: white;
        }

        .buttons {
            display: flex;
            gap: 15px;
            margin-top: 20px;
        }

        .btn-secondary {
            background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
        }

        .btn-secondary:hover {
            box-shadow: 0 10px 20px rgba(107, 114, 128, 0.3);
        }

        @media (max-width: 768px) {
            .header h1 {
                font-size: 2rem;
            }
            
            .form-container {
                padding: 20px;
            }
            
            .buttons {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ElosTupi</h1>
            <p>Editar Consulente</p>
        </div>

        <div class="form-container">
            <?php if ($message): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <form method="POST" action="">
                <div class="form-group">
                    <label for="name" class="required">Nome do Consulente</label>
                    <input type="text" id="name" name="name" 
                           value="<?php echo htmlspecialchars($_POST['name'] ?? $consulente['name']); ?>" 
                           required>
                    <div class="help-text">Nome completo do consulente</div>
                </div>

                <div class="form-group">
                    <label for="phone" class="required">Telefone</label>
                    <input type="tel" id="phone" name="phone" 
                           value="<?php echo htmlspecialchars($_POST['phone'] ?? $consulente['phone']); ?>" 
                           placeholder="(351) 999999999" required>
                    <div class="help-text">Número de telefone para contacto</div>
                </div>

                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" 
                           value="<?php echo htmlspecialchars($_POST['email'] ?? $consulente['email'] ?? ''); ?>" 
                           placeholder="email@exemplo.com">
                    <div class="help-text">Endereço de email (opcional)</div>
                </div>

                <div class="form-group">
                    <label for="notes">Notas</label>
                    <textarea id="notes" name="notes" 
                              placeholder="Informações adicionais sobre o consulente..."><?php echo htmlspecialchars($_POST['notes'] ?? $consulente['notes'] ?? ''); ?></textarea>
                    <div class="help-text">Observações ou informações relevantes</div>
                </div>

                <div class="buttons">
                    <button type="submit" class="btn">
                        Atualizar Consulente
                    </button>
                    <a href="list_consulentes.php" class="btn btn-secondary" style="text-decoration: none; text-align: center;">
                        Cancelar
                    </a>
                </div>
            </form>

            <div class="nav-links">
                <a href="list_consulentes.php">Ver Consulentes</a>
                <a href="add_consulente.php">Adicionar Novo</a>
                <a href="list_products.php">Gestão de Produtos</a>
                <a href="../">Voltar ao App</a>
                <a href="logout.php" style="color: #dc2626;">Terminar Sessão</a>
            </div>
        </div>
    </div>

    <script>
        // Validação em tempo real
        document.getElementById('name').addEventListener('input', function() {
            this.value = this.value.trim();
        });

        document.getElementById('phone').addEventListener('input', function() {
            this.value = this.value.trim();
        });

        document.getElementById('email').addEventListener('input', function() {
            this.value = this.value.trim();
        });

        // Auto-focus no primeiro campo
        document.getElementById('name').focus();
    </script>
</body>
</html>
