<?php
session_start();

// PIN de acesso
$correctPin = '561409';

$error = '';
$success = '';

// Verificar mensagens
if (isset($_GET['message']) && isset($_GET['type'])) {
    if ($_GET['type'] === 'success') {
        $success = $_GET['message'];
    } else {
        $error = $_GET['message'];
    }
}

// Processar login
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $pin = $_POST['pin'] ?? '';
    
    if ($pin === $correctPin) {
        $_SESSION['authenticated'] = true;
        $_SESSION['login_time'] = time();
        
        // Redirecionar para a página solicitada ou para list_products.php
        $redirect = $_GET['redirect'] ?? 'list_products.php';
        header('Location: ' . $redirect);
        exit;
    } else {
        $error = 'PIN incorreto. Tente novamente.';
    }
}

// Se já está autenticado, redirecionar
if (isset($_SESSION['authenticated']) && $_SESSION['authenticated'] === true) {
    $redirect = $_GET['redirect'] ?? 'list_products.php';
    header('Location: ' . $redirect);
    exit;
}
?>

<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ElosTupi - Acesso Administrativo</title>
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
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .login-container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
            width: 100%;
            max-width: 400px;
        }

        .header {
            background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
            color: white;
            padding: 40px 30px;
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
            padding: 40px 30px;
        }

        .error-message {
            background: #fef2f2;
            color: #dc2626;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 25px;
            border: 1px solid #fecaca;
            font-weight: 500;
        }

        .success-message {
            background: #dcfce7;
            color: #166534;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 25px;
            border: 1px solid #bbf7d0;
            font-weight: 500;
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

        input {
            width: 100%;
            padding: 15px 20px;
            border: 2px solid #e5e7eb;
            border-radius: 10px;
            font-size: 1.2rem;
            transition: all 0.3s ease;
            background: #f9fafb;
            text-align: center;
            letter-spacing: 2px;
            font-weight: 600;
        }

        input:focus {
            outline: none;
            border-color: #4f46e5;
            background: white;
            box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
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
            width: 100%;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 20px rgba(79, 70, 229, 0.3);
        }

        .btn:active {
            transform: translateY(0);
        }

        .pin-info {
            text-align: center;
            margin-top: 20px;
            color: #6b7280;
            font-size: 0.9rem;
        }

        .security-icon {
            font-size: 3rem;
            margin-bottom: 20px;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="header">
            <div class="security-icon">🔒</div>
            <h1>ElosTupi</h1>
            <p>Acesso Administrativo</p>
        </div>

        <div class="form-container">
            <?php if ($error): ?>
                <div class="error-message">
                    <?php echo htmlspecialchars($error); ?>
                </div>
            <?php endif; ?>

            <?php if ($success): ?>
                <div class="success-message">
                    <?php echo htmlspecialchars($success); ?>
                </div>
            <?php endif; ?>

            <form method="POST">
                <div class="form-group">
                    <label for="pin">Código PIN</label>
                    <input type="password" id="pin" name="pin" 
                           placeholder="••••••" 
                           maxlength="6" 
                           pattern="[0-9]{6}"
                           inputmode="numeric"
                           autocomplete="off"
                           required>
                </div>

                <button type="submit" class="btn">Aceder ao Sistema</button>
            </form>

            <div class="pin-info">
                <p>Introduza o código PIN de 6 dígitos para aceder ao painel administrativo.</p>
            </div>
        </div>
    </div>

    <script>
        // Focar no campo PIN automaticamente
        document.getElementById('pin').focus();
        
        // Permitir apenas números
        document.getElementById('pin').addEventListener('input', function(e) {
            this.value = this.value.replace(/[^0-9]/g, '');
        });
    </script>
</body>
</html> 