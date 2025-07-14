<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

$message = '';
$messageType = '';

// Verificar mensagens de redirecionamento
if (isset($_GET['message']) && isset($_GET['type'])) {
    $message = $_GET['message'];
    $messageType = $_GET['type'];
}

// Processar ações
if (isset($_GET['action']) && isset($_GET['id'])) {
    $action = $_GET['action'];
    $id = $_GET['id'];
    
    try {
        if ($action === 'delete') {
            $stmt = $pdo->prepare("DELETE FROM products WHERE id = ?");
            $stmt->execute([$id]);
            $message = 'Produto removido com sucesso!';
            $messageType = 'success';
        }
    } catch (Exception $e) {
        $message = 'Erro: ' . $e->getMessage();
        $messageType = 'error';
    }
}

// Buscar produtos
$products = [];
try {
    $stmt = $pdo->query("SELECT * FROM products ORDER BY name");
    $products = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $message = 'Erro ao carregar produtos: ' . $e->getMessage();
    $messageType = 'error';
}

// Buscar categorias para filtro usando a função do db_config.php
$categories = getCategories($pdo);

$selectedCategory = $_GET['category'] ?? '';
$searchQuery = $_GET['search'] ?? '';

// Filtrar produtos
$filteredProducts = $products;
if ($selectedCategory) {
    $filteredProducts = array_filter($filteredProducts, function($product) use ($selectedCategory) {
        return $product['category'] === $selectedCategory;
    });
}

if ($searchQuery) {
    $filteredProducts = array_filter($filteredProducts, function($product) use ($searchQuery) {
        return stripos($product['name'], $searchQuery) !== false || 
               stripos($product['description'], $searchQuery) !== false;
    });
}
?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ElosTupi - Lista de Produtos</title>
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

        .content {
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

        .filters {
            display: grid;
            grid-template-columns: 1fr 1fr auto;
            gap: 20px;
            margin-bottom: 30px;
            align-items: end;
        }

        .filter-group {
            display: flex;
            flex-direction: column;
        }

        .filter-group label {
            margin-bottom: 8px;
            font-weight: 600;
            color: #374151;
        }

        .filter-group input,
        .filter-group select {
            padding: 12px 16px;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 1rem;
            background: #f9fafb;
        }

        .filter-group input:focus,
        .filter-group select:focus {
            outline: none;
            border-color: #4f46e5;
            background: white;
        }

        .btn {
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 10px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-block;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3);
        }

        .btn-danger {
            background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
        }

        .btn-success {
            background: linear-gradient(135deg, #059669 0%, #047857 100%);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-card {
            background: #f8fafc;
            padding: 20px;
            border-radius: 12px;
            text-align: center;
            border: 1px solid #e2e8f0;
        }

        .stat-number {
            font-size: 2rem;
            font-weight: 700;
            color: #4f46e5;
            margin-bottom: 5px;
        }

        .stat-label {
            color: #64748b;
            font-size: 0.9rem;
        }

        .products-table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        .products-table th,
        .products-table td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
        }

        .products-table th {
            background: #f8fafc;
            font-weight: 600;
            color: #374151;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .products-table tr:hover {
            background: #f9fafb;
        }

        .product-image {
            width: 50px;
            height: 50px;
            border-radius: 8px;
            object-fit: cover;
        }

        .product-name {
            font-weight: 600;
            color: #374151;
        }

        .product-category {
            background: #e0e7ff;
            color: #3730a3;
            padding: 4px 8px;
            border-radius: 6px;
            font-size: 0.8rem;
            font-weight: 500;
        }

        .product-price {
            font-weight: 600;
            color: #059669;
        }

        .product-stock {
            font-weight: 600;
        }

        .stock-low {
            color: #dc2626;
        }

        .stock-ok {
            color: #059669;
        }

        .actions {
            display: flex;
            gap: 8px;
        }

        .nav-links {
            text-align: center;
            margin-top: 30px;
        }

        .nav-links a {
            color: #4f46e5;
            text-decoration: none;
            margin: 0 10px;
            padding: 8px 16px;
            border-radius: 8px;
            transition: all 0.3s ease;
        }

        .nav-links a:hover {
            background: #4f46e5;
            color: white;
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #6b7280;
        }

        .empty-state h3 {
            font-size: 1.5rem;
            margin-bottom: 10px;
            color: #374151;
        }

        @media (max-width: 768px) {
            .filters {
                grid-template-columns: 1fr;
            }
            
            .stats {
                grid-template-columns: 1fr;
            }
            
            .products-table {
                font-size: 0.9rem;
            }
            
            .products-table th,
            .products-table td {
                padding: 10px;
            }
            
            .actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>ElosTupi</h1>
            <p>Lista de Produtos</p>
        </div>

        <div class="content">
            <?php if ($message): ?>
                <div class="message <?php echo $messageType; ?>">
                    <?php echo htmlspecialchars($message); ?>
                </div>
            <?php endif; ?>

            <!-- Estatísticas -->
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-number"><?php echo count($products); ?></div>
                    <div class="stat-label">Total de Produtos</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number"><?php echo count($filteredProducts); ?></div>
                    <div class="stat-label">Produtos Filtrados</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number"><?php echo count($categories); ?></div>
                    <div class="stat-label">Categorias</div>
                </div>
            </div>

            <!-- Filtros -->
            <form method="GET" action="">
                <div class="filters">
                    <div class="filter-group">
                        <label for="search">Pesquisar</label>
                        <input type="text" id="search" name="search" value="<?php echo htmlspecialchars($searchQuery); ?>" placeholder="Nome ou descrição...">
                    </div>
                    <div class="filter-group">
                        <label for="category">Categoria</label>
                        <select id="category" name="category">
                            <option value="">Todas as categorias</option>
                            <?php foreach ($categories as $cat): ?>
                                <option value="<?php echo htmlspecialchars($cat); ?>" <?php echo $selectedCategory === $cat ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($cat); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="filter-group">
                        <button type="submit" class="btn">Filtrar</button>
                    </div>
                </div>
            </form>

            <!-- Tabela de Produtos -->
            <?php if (empty($filteredProducts)): ?>
                <div class="empty-state">
                    <h3>Nenhum produto encontrado</h3>
                    <p>Não foram encontrados produtos com os filtros aplicados.</p>
                    <a href="add_product.php" class="btn">Adicionar Primeiro Produto</a>
                </div>
            <?php else: ?>
                <table class="products-table">
                    <thead>
                        <tr>
                            <th>Imagem</th>
                            <th>Produto</th>
                            <th>Categoria</th>
                            <th>Preço</th>
                            <th>Stock</th>
                            <th>Ações</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($filteredProducts as $product): ?>
                            <tr>
                                <td>
                                    <?php if (!empty($product['imageUrl'])): ?>
                                        <img src="<?php echo htmlspecialchars($product['imageUrl']); ?>" 
                                             alt="<?php echo htmlspecialchars($product['name']); ?>" 
                                             class="product-image"
                                             onerror="this.style.display='none'">
                                    <?php else: ?>
                                        <div style="width: 50px; height: 50px; background: #e5e7eb; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                            <span style="color: #9ca3af; font-size: 12px;">Sem img</span>
                                        </div>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <div class="product-name"><?php echo htmlspecialchars($product['name']); ?></div>
                                    <?php if (!empty($product['description'])): ?>
                                        <div style="font-size: 0.8rem; color: #6b7280; margin-top: 4px;">
                                            <?php echo htmlspecialchars(substr($product['description'], 0, 50)) . (strlen($product['description']) > 50 ? '...' : ''); ?>
                                        </div>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <?php if (!empty($product['category'])): ?>
                                        <span class="product-category"><?php echo htmlspecialchars($product['category']); ?></span>
                                    <?php else: ?>
                                        <span style="color: #9ca3af;">Sem categoria</span>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <div class="product-price">€<?php echo number_format($product['price'], 2, ',', '.'); ?></div>
                                    <?php if (!empty($product['price2'])): ?>
                                        <div style="font-size: 0.8rem; color: #f59e0b;">
                                            Revenda: €<?php echo number_format($product['price2'], 2, ',', '.'); ?>
                                        </div>
                                    <?php endif; ?>
                                </td>
                                <td>
                                    <span class="product-stock <?php echo $product['stock'] <= 5 ? 'stock-low' : 'stock-ok'; ?>">
                                        <?php echo $product['stock']; ?>
                                    </span>
                                </td>
                                <td>
                                    <div class="actions">
                                        <a href="edit_product.php?id=<?php echo urlencode($product['id']); ?>" class="btn btn-success" style="padding: 8px 12px; font-size: 0.8rem;">
                                            Editar
                                        </a>
                                        <a href="duplicate_product.php?id=<?php echo urlencode($product['id']); ?>" class="btn" style="padding: 8px 12px; font-size: 0.8rem; background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); color: white;">
                                            Duplicar
                                        </a>
                                        <a href="?action=delete&id=<?php echo urlencode($product['id']); ?>" 
                                           class="btn btn-danger" 
                                           style="padding: 8px 12px; font-size: 0.8rem;"
                                           onclick="return confirm('Tem certeza que deseja remover este produto?')">
                                            Remover
                                        </a>
                                    </div>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>

            <div class="nav-links">
                <a href="add_product.php">Adicionar Produto</a>
                <a href="../">Voltar ao App</a>
                <a href="logout.php" style="color: #dc2626;">Terminar Sessão</a>
            </div>
        </div>
    </div>
</body>
</html> 