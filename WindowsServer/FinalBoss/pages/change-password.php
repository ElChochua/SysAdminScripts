<?php
    session_start();
    require_once __DIR__ . '/../core/DatabaseManager.php';
    require_once __DIR__ . '/../core/auth.php';
    if (!isset($_SESSION['user'])) {
        header("Location: ../index.php");
        exit();
    }
    $dbManager = new DatabaseManager();
    $auth = new Authenticator();
    if($_POST){
        if($_POST['new_password'] !== $_POST['confirm_password']){
            $error = "Las contraseñas no coinciden.";
        } else {
            $dbManager->updatePassword($_SESSION['user'], $_POST['current_password'], $_POST['new_password'], $_POST['confirm_password']);
            $_SESSION['message'] = "Contraseña actualizada correctamente. Por favor, inicia sesión de nuevo.";
            $auth->logout();
        }
    }
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cambiar Contraseña - Sistema RRHH</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { background-color: #f8f9fa; }
        .navbar-brand { font-weight: bold; }
        .card { border: none; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .card-header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
    </style>
</head>
<body>
    <?php include './shared/navbar.php'; ?>
    
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-md-8 col-lg-6">
                <div class="card">
                    <div class="card-header">
                        <h4 class="mb-0">
                            <i class="fas fa-key me-2"></i>Cambiar Contraseña
                        </h4>
                    </div>
                    <div class="card-body">
                        <form method="POST" action="">
                            <div class="mb-3">
                                <label for="current_password" class="form-label">
                                    <i class="fas fa-lock me-2"></i>Contraseña Actual
                                </label>
                                <input type="password" class="form-control" id="current_password" name="current_password" required>
                            </div>
                            
                            <div class="mb-3">
                                <label for="new_password" class="form-label">
                                    <i class="fas fa-key me-2"></i>Nueva Contraseña
                                </label>
                                <input type="password" class="form-control" id="new_password" name="new_password" required>
                                <div class="form-text">
                                    La contraseña debe tener al menos 8 caracteres, incluir mayúsculas, minúsculas y números.
                                </div>
                            </div>
                            
                            <div class="mb-3">
                                <label for="confirm_password" class="form-label">
                                    <i class="fas fa-check-circle me-2"></i>Confirmar Nueva Contraseña
                                </label>
                                <input type="password" class="form-control" id="confirm_password" name="confirm_password" required>
                            </div>
                            
                            <div class="alert alert-info">
                                <i class="fas fa-info-circle me-2"></i>
                                <strong>Importante:</strong> Al cambiar tu contraseña, se cerrará tu sesión en todos los dispositivos.
                            </div>
                            
                            <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                                <a href="dashboard.php" class="btn btn-secondary me-md-2">
                                    <i class="fas fa-times me-2"></i>Cancelar
                                </a>
                                <button type="submit" class="btn btn-primary">
                                    <i class="fas fa-save me-2"></i>Cambiar Contraseña
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
