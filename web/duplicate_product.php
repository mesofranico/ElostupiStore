<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

$message = '';
$messageType = '';
$originalProduct = null;

// Verificar se foi fornecido um ID
if (!isset($_GET['id'])) {
    header('Location: list_products.php');
    exit;
}

$productId = $_GET['id'];

// Verificar se o produto existe
if (!productExists($pdo, $productId)) {
    $message = 'Produto não encontrado!';
    $messageType = 'error';
} else {
    // Buscar dados do produto original
    $originalProduct = getProductById($pdo, $productId);
    
    if (!$originalProduct) {
        $message = 'Erro ao carregar dados do produto!';
        $messageType = 'error';
    }
}

// Processar formulário de criação
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Validar dados obrigatórios
        if (empty($_POST['id']) || empty($_POST['name']) || empty($_POST['price'])) {
            throw new Exception('ID, Nome e Preço são obrigatórios');
        }

        // Preparar dados
        $id = trim($_POST['id']);
        $name = trim($_POST['name']);
        $price = floatval($_POST['price']);
        $price2 = !empty($_POST['price2']) ? floatval($_POST['price2']) : null;
        $description = trim($_POST['description'] ?? '');
        $imageUrl = trim($_POST['imageUrl'] ?? '');
        $category = trim($_POST['category'] ?? '');
        $stock = !empty($_POST['stock']) ? intval($_POST['stock']) : 0;

        // Novo bloco: Baixar e salvar imagem localmente se URL for fornecido
        $localImagePath = '';
        if (!empty($imageUrl) && filter_var($imageUrl, FILTER_VALIDATE_URL)) {
            $imageContent = @file_get_contents($imageUrl);
            if ($imageContent === false) {
                throw new Exception('Não foi possível baixar a imagem do URL fornecido.');
            }
            // Detectar extensão da imagem
            $finfo = new finfo(FILEINFO_MIME_TYPE);
            $mimeType = $finfo->buffer($imageContent);
            $ext = '';
            switch ($mimeType) {
                case 'image/jpeg': $ext = 'jpg'; break;
                case 'image/png': $ext = 'png'; break;
                case 'image/gif': $ext = 'gif'; break;
                case 'image/webp': $ext = 'webp'; break;
                default:
                    throw new Exception('Tipo de imagem não suportado: ' . $mimeType);
            }
            // Garantir que a pasta imagens existe
            $imagesDir = __DIR__ . '/imagens';
            if (!is_dir($imagesDir)) {
                mkdir($imagesDir, 0777, true);
            }
            $localImagePath = 'imagens/' . $id . '.' . $ext;
            $fullImagePath = $imagesDir . '/' . $id . '.' . $ext;
            if (file_put_contents($fullImagePath, $imageContent) === false) {
                throw new Exception('Erro ao salvar a imagem no servidor.');
            }
        }

        // Verificar se o novo ID já existe
        $stmt = $pdo->prepare("SELECT id FROM products WHERE id = ?");
        $stmt->execute([$id]);
        
        if ($stmt->fetch()) {
            throw new Exception('Produto com este ID já existe');
        }

        // Inserir novo produto
        $stmt = $pdo->prepare("
            INSERT INTO products (id, name, price, price2, description, imageUrl, category, stock) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        $stmt->execute([$id, $name, $price, $price2, $description, $localImagePath ?: $imageUrl, $category, $stock]);
        
        // Redirecionar para a lista de produtos após sucesso
        header('Location: list_products.php?message=Produto duplicado com sucesso!&type=success');
        exit;
        
    } catch (Exception $e) {
        $message = 'Erro: ' . $e->getMessage();
        $messageType = 'error';
    }
}

// Buscar categorias existentes
$categories = getCategories($pdo);
?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ElosTupi - Duplicar Produto</title>
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
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
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

        .original-product {
            background: #f8fafc;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 30px;
        }

        .original-product h3 {
            color: #374151;
            margin-bottom: 15px;
            font-size: 1.2rem;
        }

        .original-info {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            font-size: 0.9rem;
        }

        .original-info div {
            background: white;
            padding: 10px;
            border-radius: 8px;
            border: 1px solid #e5e7eb;
        }

        .original-info strong {
            color: #374151;
            display: block;
            margin-bottom: 5px;
        }

        .form-group {
            margin-bottom: 25px;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }

        .form-group.full-width {
            grid-column: 1 / -1;
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

        input, textarea, select {
            width: 100%;
            padding: 12px 16px;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 1rem;
            transition: all 0.3s ease;
            background: #f9fafb;
        }

        input:focus, textarea:focus, select:focus {
            outline: none;
            border-color: #8b5cf6;
            background: white;
            box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
        }

        textarea {
            resize: vertical;
            min-height: 100px;
        }

        .btn {
            background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 10px;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
            margin-right: 10px;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(139, 92, 246, 0.3);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn-secondary {
            background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
        }

        .btn-secondary:hover {
            box-shadow: 0 10px 20px rgba(107, 114, 128, 0.3);
        }

        .section-title {
            font-size: 1.3rem;
            font-weight: 700;
            color: #374151;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e5e7eb;
        }

        .help-text {
            font-size: 0.85rem;
            color: #6b7280;
            margin-top: 5px;
        }

        .buttons {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }

        @media (max-width: 768px) {
            .form-row {
                grid-template-columns: 1fr;
            }
            
            .buttons {
                flex-direction: column;
            }
            
            .btn {
                margin-right: 0;
                margin-bottom: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ElosTupi</h1>
            <p>Duplicar Produto</p>
        </div>

        <div class="form-container">
            <?php if ($message): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <?php if ($originalProduct): ?>
                <!-- Informações do Produto Original -->
                <div class="original-product">
                    <h3>📋 Produto Original</h3>
                    <div class="original-info">
                        <div>
                            <strong>ID:</strong> <?php echo htmlspecialchars($originalProduct['id']); ?>
                        </div>
                        <div>
                            <strong>Nome:</strong> <?php echo htmlspecialchars($originalProduct['name']); ?>
                        </div>
                        <div>
                            <strong>Preço:</strong> €<?php echo number_format($originalProduct['price'], 2, ',', '.'); ?>
                        </div>
                        <?php if (!empty($originalProduct['price2'])): ?>
                        <div>
                            <strong>Preço Revenda:</strong> €<?php echo number_format($originalProduct['price2'], 2, ',', '.'); ?>
                        </div>
                        <?php endif; ?>
                        <div>
                            <strong>Categoria:</strong> <?php echo htmlspecialchars($originalProduct['category'] ?? 'Sem categoria'); ?>
                        </div>
                        <div>
                            <strong>Stock:</strong> <?php echo $originalProduct['stock']; ?>
                        </div>
                    </div>
                </div>

                <form method="POST">
                    <!-- ID do Produto -->
                    <div class="section-title">Campos Obrigatórios</div>
                    
                    <div class="form-group">
                        <label for="id" class="required">ID do Novo Produto</label>
                        <input type="text" id="id" name="id" 
                               value="<?php echo htmlspecialchars($_POST['id'] ?? ''); ?>" 
                               placeholder="ID único para o novo produto"
                               required>
                        <div class="help-text">Identificador único do novo produto (diferente do original)</div>
                    </div>

                    <div class="form-group">
                        <label for="name" class="required">Nome do Produto</label>
                        <input type="text" id="name" name="name" 
                               value="<?php echo htmlspecialchars($_POST['name'] ?? $originalProduct['name']); ?>" 
                               required>
                        <div class="help-text">Nome do novo produto</div>
                    </div>

                    <div class="form-group">
                        <label for="price" class="required">Preço (€)</label>
                        <input type="number" id="price" name="price" 
                               value="<?php echo htmlspecialchars($_POST['price'] ?? $originalProduct['price']); ?>" 
                               step="0.01" min="0" required>
                        <div class="help-text">Preço de venda em euros</div>
                    </div>

                    <!-- Campos Opcionais -->
                    <div class="section-title">Campos Opcionais</div>

                    <div class="form-group">
                        <label for="price2">Preço de Revenda (€)</label>
                        <input type="number" id="price2" name="price2" 
                               value="<?php echo htmlspecialchars($_POST['price2'] ?? $originalProduct['price2'] ?? ''); ?>" 
                               step="0.01" min="0">
                        <div class="help-text">Preço de revenda (opcional)</div>
                    </div>

                    <div class="form-group">
                        <label for="description">Descrição</label>
                        <textarea id="description" name="description" 
                                  placeholder="Descrição detalhada do produto..."><?php echo htmlspecialchars($_POST['description'] ?? $originalProduct['description'] ?? ''); ?></textarea>
                        <div class="help-text">Descrição opcional do produto</div>
                    </div>

                    <div class="form-group">
                        <label for="imageUrl">URL da Imagem</label>
                        <input type="url" id="imageUrl" name="imageUrl" 
                               value="<?php echo htmlspecialchars($_POST['imageUrl'] ?? $originalProduct['imageUrl'] ?? ''); ?>">
                        <div class="help-text">Link para a imagem do produto</div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label for="category">Categoria</label>
                            <select id="category" name="category">
                                <option value="">Selecionar categoria...</option>
                                <?php foreach ($categories as $cat): ?>
                                    <option value="<?php echo htmlspecialchars($cat); ?>" 
                                            <?php echo (($_POST['category'] ?? $originalProduct['category'] ?? '') === $cat) ? 'selected' : ''; ?>>
                                        <?php echo htmlspecialchars($cat); ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <div class="help-text">Categoria do produto</div>
                        </div>
                        
                        <div class="form-group">
                            <label for="stock">Stock</label>
                            <input type="number" id="stock" name="stock" 
                                   value="<?php echo htmlspecialchars($_POST['stock'] ?? $originalProduct['stock'] ?? '0'); ?>" 
                                   min="0">
                            <div class="help-text">Quantidade em stock</div>
                        </div>
                    </div>

                    <!-- Botões -->
                    <div class="buttons">
                        <button type="submit" class="btn">Criar Produto Duplicado</button>
                        <a href="list_products.php" class="btn btn-secondary">Cancelar</a>
                    </div>
                </form>
            <?php else: ?>
                <div class="message error">
                    Produto não encontrado ou erro ao carregar dados.
                </div>
                <div style="text-align: center; margin-top: 20px;">
                    <a href="list_products.php" class="btn">Voltar à Lista</a>
                </div>
            <?php endif; ?>
        </div>
    </div>

    <script>
        // Validação em tempo real
        document.getElementById('price').addEventListener('input', function() {
            if (this.value < 0) {
                this.value = 0;
            }
        });

        document.getElementById('price2').addEventListener('input', function() {
            if (this.value < 0) {
                this.value = 0;
            }
        });

        document.getElementById('stock').addEventListener('input', function() {
            if (this.value < 0) {
                this.value = 0;
            }
        });

        // Auto-focus no campo ID
        document.getElementById('id').focus();
    </script>
</body>
</html> 