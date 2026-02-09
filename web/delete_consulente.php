<?php
// Verificar autenticação
require_once 'auth_check.php';

// Incluir configuração da base de dados
require_once 'db_config.php';

// Verificar se foi fornecido um ID
if (!isset($_GET['id'])) {
    header('Location: list_consulentes.php?message=ID do consulente não fornecido!&type=error');
    exit;
}

$consulenteId = $_GET['id'];

try {
    // Verificar se o consulente existe
    $stmt = $pdo->prepare("SELECT name FROM consulentes WHERE id = ?");
    $stmt->execute([$consulenteId]);
    $consulente = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$consulente) {
        header('Location: list_consulentes.php?message=Consulente não encontrado!&type=error');
        exit;
    }
    
    $consulenteName = $consulente['name'];
    
    // Contar sessões relacionadas
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM consulente_sessions WHERE consulente_id = ?");
    $stmt->execute([$consulenteId]);
    $sessionsCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    // Deletar o consulente (as sessões serão automaticamente removidas devido ao ON DELETE CASCADE)
    $stmt = $pdo->prepare("DELETE FROM consulentes WHERE id = ?");
    $stmt->execute([$consulenteId]);
    
    // Redirecionar com mensagem de sucesso
    $message = "Consulente '$consulenteName' eliminado com sucesso!";
    if ($sessionsCount > 0) {
        $message .= " Também foram eliminadas $sessionsCount sessões relacionadas.";
    }
    
    header('Location: list_consulentes.php?message=' . urlencode($message) . '&type=success');
    exit;
    
} catch(PDOException $e) {
    header('Location: list_consulentes.php?message=Erro ao eliminar consulente: ' . urlencode($e->getMessage()) . '&type=error');
    exit;
}
?>
