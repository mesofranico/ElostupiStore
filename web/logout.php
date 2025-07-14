<?php
session_start();

// Destruir a sessão
session_destroy();

// Redirecionar para a página de login
header('Location: index.php?message=Sessão terminada com sucesso.&type=success');
exit;
?> 