<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

$message = '';
$messageType = '';
$product = null;

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
    // Buscar dados do produto
    $product = getProductById($pdo, $productId);
    
    if (!$product) {
        $message = 'Erro ao carregar dados do produto!';
        $messageType = 'error';
    }
}

// Processar formulário de atualização
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $product) {
    try {
        // Validar dados obrigatórios
        if (empty($_POST['name']) || empty($_POST['price'])) {
            throw new Exception('Nome e Preço são obrigatórios');
        }

        // Preparar dados
        $name = trim($_POST['name']);
        $price = floatval($_POST['price']);
        $price2 = !empty($_POST['price2']) ? floatval($_POST['price2']) : null;
        $description = trim($_POST['description'] ?? '');
        $imageUrl = trim($_POST['imageUrl'] ?? '');
        $category = trim($_POST['category'] ?? '');
        $stock = !empty($_POST['stock']) ? intval($_POST['stock']) : 0;

        // Processar imagem - prioridade para upload local, depois URL
        $localImagePath = $product['imageUrl']; // Manter imagem atual por defeito
        $imageUploaded = false; // Flag para controlar se foi feito upload
        
        // Verificar se foi feito upload de uma imagem local
        if (isset($_FILES['imageFile']) && $_FILES['imageFile']['error'] === UPLOAD_ERR_OK && !empty($_FILES['imageFile']['name'])) {
            $uploadedFile = $_FILES['imageFile'];
            
            // Validar tipo de ficheiro
            $allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
            $finfo = new finfo(FILEINFO_MIME_TYPE);
            $mimeType = $finfo->file($uploadedFile['tmp_name']);
            
            if (!in_array($mimeType, $allowedTypes)) {
                throw new Exception('Tipo de ficheiro não suportado. Utilize apenas JPG, PNG, GIF ou WebP.');
            }
            
            // Validar tamanho (máximo 5MB)
            if ($uploadedFile['size'] > 5 * 1024 * 1024) {
                throw new Exception('A imagem é demasiado grande. Tamanho máximo: 5MB.');
            }
            
            // Determinar extensão
            $ext = '';
            switch ($mimeType) {
                case 'image/jpeg': $ext = 'jpg'; break;
                case 'image/png': $ext = 'png'; break;
                case 'image/gif': $ext = 'gif'; break;
                case 'image/webp': $ext = 'webp'; break;
            }
            
            // Garantir que a pasta imagens existe
            $imagesDir = __DIR__ . '/imagens';
            if (!is_dir($imagesDir)) {
                mkdir($imagesDir, 0777, true);
            }
            
            $localImagePath = 'imagens/' . $productId . '.' . $ext;
            $fullImagePath = $imagesDir . '/' . $productId . '.' . $ext;
            
            // Mover ficheiro para pasta de imagens
            if (!move_uploaded_file($uploadedFile['tmp_name'], $fullImagePath)) {
                throw new Exception('Erro ao guardar a imagem no servidor.');
            }
            
            $imageUploaded = true; // Marcar que foi feito upload com sucesso
        }
        // Se não houve upload local, tentar baixar do URL (apenas se diferente do atual e não foi feito upload)
        elseif (!$imageUploaded && !empty($imageUrl) && $imageUrl !== $product['imageUrl']) {
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
            $localImagePath = 'imagens/' . $productId . '.' . $ext;
            $fullImagePath = $imagesDir . '/' . $productId . '.' . $ext;
            if (file_put_contents($fullImagePath, $imageContent) === false) {
                throw new Exception('Erro ao salvar a imagem no servidor.');
            }
        }

        // Atualizar produto
        $stmt = $pdo->prepare("
            UPDATE products 
            SET name = ?, price = ?, price2 = ?, description = ?, imageUrl = ?, category = ?, stock = ? 
            WHERE id = ?
        ");
        
        $stmt->execute([$name, $price, $price2, $description, $localImagePath, $category, $stock, $productId]);
        
        // Redirecionar para a lista de produtos após sucesso
        header('Location: list_products.php?message=Produto atualizado com sucesso!&type=success');
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
    <title>ElosTupi - Editar Produto</title>
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
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
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
            border-color: #4f46e5;
            background: white;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
        }

        input:disabled, textarea:disabled, select:disabled {
            background: #f3f4f6;
            color: #9ca3af;
            cursor: not-allowed;
            border-color: #d1d5db;
        }

        input:disabled:focus, textarea:disabled:focus, select:disabled:focus {
            box-shadow: none;
        }

        textarea {
            resize: vertical;
            min-height: 100px;
        }

        .btn {
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
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
            box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3);
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

        .product-id {
            background: #f3f4f6;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
            border: 2px solid #e5e7eb;
        }

        .product-id label {
            font-weight: 700;
            color: #374151;
            margin-bottom: 5px;
        }

        .product-id input {
            background: #e5e7eb;
            color: #6b7280;
            cursor: not-allowed;
        }

        .buttons {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }

        .image-options {
            background: #f8fafc;
            border: 2px solid #e2e8f0;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .image-option {
            margin-bottom: 15px;
        }

        .image-option:last-child {
            margin-bottom: 0;
        }

        .image-option label {
            font-weight: 600;
            color: #374151;
            margin-bottom: 8px;
            display: block;
        }

        .file-input-wrapper {
            position: relative;
            display: inline-block;
            width: 100%;
        }

        .file-input {
            opacity: 0;
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            cursor: pointer;
        }

        .file-input-label {
            display: block;
            padding: 12px 16px;
            border: 2px dashed #d1d5db;
            border-radius: 10px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s ease;
            background: #f9fafb;
            color: #6b7280;
        }

        .file-input-label:hover {
            border-color: #4f46e5;
            background: #f0f4ff;
            color: #4f46e5;
        }

        .file-input:focus + .file-input-label {
            border-color: #4f46e5;
            background: #f0f4ff;
            color: #4f46e5;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
        }

        .image-preview {
            margin-top: 10px;
            text-align: center;
        }

        .image-preview img {
            max-width: 200px;
            max-height: 200px;
            border-radius: 8px;
            border: 2px solid #e5e7eb;
        }

        .or-divider {
            text-align: center;
            margin: 20px 0;
            position: relative;
        }

        .or-divider::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 1px;
            background: #e5e7eb;
        }

        .or-divider span {
            background: white;
            padding: 0 15px;
            color: #6b7280;
            font-size: 0.9rem;
        }

        .current-image {
            background: #f0f9ff;
            border: 2px solid #0ea5e9;
            border-radius: 12px;
            padding: 15px;
            margin-bottom: 15px;
        }

        .current-image img {
            max-width: 150px;
            max-height: 150px;
            border-radius: 8px;
            border: 2px solid #e5e7eb;
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
            <p>Editar Produto</p>
        </div>

        <div class="form-container">
            <?php if ($message): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <?php if ($product): ?>
                <form method="POST" enctype="multipart/form-data">
                    <!-- ID do Produto (não editável) -->
                    <div class="product-id">
                        <label>ID do Produto</label>
                        <input type="text" value="<?php echo htmlspecialchars($product['id']); ?>" readonly>
                        <div class="help-text">O ID do produto não pode ser alterado</div>
                    </div>

                    <!-- Informações Básicas -->
                    <div class="section-title">Informações Básicas</div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="name" class="required">Nome do Produto</label>
                            <input type="text" id="name" name="name" 
                                   value="<?php echo htmlspecialchars($product['name']); ?>" 
                                   required>
                        </div>
                        <div class="form-group">
                            <label for="category">Categoria</label>
                            <select id="category" name="category">
                                <option value="">Selecionar categoria</option>
                                <?php foreach ($categories as $cat): ?>
                                    <option value="<?php echo htmlspecialchars($cat); ?>" 
                                            <?php echo $product['category'] === $cat ? 'selected' : ''; ?>>
                                        <?php echo htmlspecialchars($cat); ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <div class="help-text">Deixe em branco para criar uma nova categoria</div>
                        </div>
                    </div>

                    <div class="form-group full-width">
                        <label for="description">Descrição</label>
                        <textarea id="description" name="description" 
                                  placeholder="Descrição detalhada do produto..."><?php echo htmlspecialchars($product['description'] ?? ''); ?></textarea>
                    </div>

                    <!-- Preços -->
                    <div class="section-title">Preços</div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="price" class="required">Preço Principal (€)</label>
                            <input type="number" id="price" name="price" 
                                   value="<?php echo $product['price']; ?>" 
                                   step="0.01" min="0" required>
                        </div>
                        <div class="form-group">
                            <label for="price2">Preço de Revenda (€)</label>
                            <input type="number" id="price2" name="price2" 
                                   value="<?php echo $product['price2'] ?? ''; ?>" 
                                   step="0.01" min="0">
                            <div class="help-text">Opcional - para revendedores</div>
                        </div>
                    </div>

                    <!-- Stock e Imagem -->
                    <div class="section-title">Stock e Imagem</div>
                    
                    <div class="form-group">
                        <label for="stock">Quantidade em Stock</label>
                        <input type="number" id="stock" name="stock" 
                               value="<?php echo $product['stock']; ?>" 
                               min="0">
                    </div>

                    <!-- Secção de Imagem -->
                    <div class="section-title">Imagem do Produto</div>
                    
                    <?php if (!empty($product['imageUrl'])): ?>
                        <div class="current-image">
                            <label>🖼️ Imagem Atual</label>
                            <div style="text-align: center; margin-top: 10px;">
                                <img src="<?php echo htmlspecialchars($product['imageUrl']); ?>" 
                                     alt="Imagem atual do produto"
                                     onerror="this.style.display='none'; this.parentNode.innerHTML='<p style=\'color: #6b7280;\'>Imagem não disponível</p>';">
                            </div>
                        </div>
                    <?php endif; ?>
                    
                    <div class="image-options">
                        <div class="image-option">
                            <label for="imageFile">📁 Carregar Nova Imagem</label>
                            <div class="file-input-wrapper">
                                <input type="file" id="imageFile" name="imageFile" class="file-input" accept="image/*">
                                <label for="imageFile" class="file-input-label">
                                    <strong>Clique aqui</strong> para selecionar uma nova imagem<br>
                                    <small>Formatos: JPG, PNG, GIF, WebP (máx. 5MB)</small>
                                </label>
                            </div>
                            <div class="image-preview" id="imagePreview" style="display: none;">
                                <img id="previewImg" src="" alt="Pré-visualização">
                            </div>
                        </div>

                        <div class="or-divider">
                            <span>ou</span>
                        </div>

                        <div class="image-option">
                            <label for="imageUrl">🌐 URL da Imagem</label>
                            <input type="url" id="imageUrl" name="imageUrl" 
                                   value="<?php echo htmlspecialchars($product['imageUrl'] ?? ''); ?>" 
                                   placeholder="https://exemplo.com/imagem.jpg">
                            <div class="help-text">Link para a imagem do produto (opcional se carregar ficheiro local)</div>
                        </div>
                    </div>

                    <!-- Botões -->
                    <div class="buttons">
                        <button type="submit" class="btn">Atualizar Produto</button>
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

        // Pré-visualização de imagem
        document.getElementById('imageFile').addEventListener('change', function(e) {
            const file = e.target.files[0];
            const preview = document.getElementById('imagePreview');
            const previewImg = document.getElementById('previewImg');
            const urlInput = document.getElementById('imageUrl');
            const urlLabel = document.querySelector('label[for="imageUrl"]');
            
            if (file) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    previewImg.src = e.target.result;
                    preview.style.display = 'block';
                };
                reader.readAsDataURL(file);
                
                // Desabilitar campo URL quando imagem local for selecionada
                urlInput.disabled = true;
                urlInput.placeholder = 'URL desabilitado - imagem local selecionada';
                urlLabel.style.opacity = '0.5';
            } else {
                preview.style.display = 'none';
                
                // Reabilitar campo URL quando nenhuma imagem local for selecionada
                urlInput.disabled = false;
                urlInput.placeholder = 'https://exemplo.com/imagem.jpg';
                urlLabel.style.opacity = '1';
            }
        });

        // Reabilitar campo URL se for limpo manualmente
        document.getElementById('imageUrl').addEventListener('input', function() {
            const fileInput = document.getElementById('imageFile');
            if (!fileInput.files.length) {
                this.disabled = false;
                this.placeholder = 'https://exemplo.com/imagem.jpg';
                document.querySelector('label[for="imageUrl"]').style.opacity = '1';
            }
        });
    </script>
</body>
</html> 