<?php
session_start();

// Verificar se está autenticado
if (!isset($_SESSION['authenticated']) || $_SESSION['authenticated'] !== true) {
    // Redirecionar para login com a página atual como destino
    $currentPage = $_SERVER['REQUEST_URI'];
    header('Location: index.php?redirect=' . urlencode($currentPage));
    exit;
}

// Verificar se a sessão não expirou (8 horas)
$sessionTimeout = 8 * 60 * 60; // 8 horas em segundos
if (isset($_SESSION['login_time']) && (time() - $_SESSION['login_time']) > $sessionTimeout) {
    // Sessão expirada, destruir e redirecionar
    session_destroy();
    header('Location: index.php?message=Sessão expirada. Faça login novamente.&type=error');
    exit;
}

// Atualizar tempo de login para manter sessão ativa
$_SESSION['login_time'] = time();
?> 