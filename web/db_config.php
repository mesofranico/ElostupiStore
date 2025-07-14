<?php
// Configuração da base de dados - Arquivo compartilhado
// Usado por add_product.php, list_products.php, edit_product.php, etc.

// Configurações da base de dados
$host = 'localhost';
$dbname = 'elostupistore'; // Altere para o nome da sua base de dados
$username = 'elostore'; // Altere para o seu utilizador MySQL
$password = 'W#S3j7busb&5Tzzf'; // Altere para a sua password MySQL

try {
    // Criar conexão PDO
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    
    // Configurar PDO para lançar exceções em caso de erro
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Configurar para usar UTF-8
    $pdo->exec("SET NAMES utf8mb4");
    
} catch(PDOException $e) {
    // Em caso de erro na conexão, retornar erro JSON
    header('Content-Type: application/json');
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erro na conexão com a base de dados: ' . $e->getMessage()
    ]);
    exit;
}

// Função para obter todas as categorias
function getCategories($pdo) {
    try {
        $stmt = $pdo->query("SELECT DISTINCT category FROM products ORDER BY category");
        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    } catch(PDOException $e) {
        return [];
    }
}

// Função para validar se um produto existe
function productExists($pdo, $id) {
    try {
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM products WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetchColumn() > 0;
    } catch(PDOException $e) {
        return false;
    }
}

// Função para obter um produto por ID
function getProductById($pdo, $id) {
    try {
        $stmt = $pdo->prepare("SELECT * FROM products WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    } catch(PDOException $e) {
        return null;
    }
}
?> 