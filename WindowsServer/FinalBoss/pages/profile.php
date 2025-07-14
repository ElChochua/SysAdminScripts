<?php
session_start();
require_once '../core/DatabaseManager.php';
if (!isset($_SESSION['user'])) {
    header("Location: index.php");
    exit();
}
$dbManager = new DatabaseManager();
// Simulación de datos del usuario (en producción vendría de la base de datos)
$user_data = $dbManager->getUserByUsername($_SESSION['user']);

// Función para formatear datos
function formatDepartment($dept) {
    $departments = [
        'desarrollo_web' => 'Desarrollo Web',
        'admin_bd' => 'Administrador de Bases de Datos',
        'rrhh' => 'Recursos Humanos',
        'ventas' => 'Ventas',
        'marketing' => 'Marketing',
        'finanzas' => 'Finanzas'
    ];
    return $departments[$dept] ?? $dept;
}

function formatStatus($status) {
    $statuses = [
        'active' => ['label' => 'Activo', 'class' => 'success'],
        'inactive' => ['label' => 'Inactivo', 'class' => 'danger'],
        'suspended' => ['label' => 'Suspendido', 'class' => 'warning']
    ];
    return $statuses[$status] ?? ['label' => $status, 'class' => 'secondary'];
}

function formatRole($role) {
    $roles = [
        'admin' => ['label' => 'Administrador', 'class' => 'danger', 'icon' => 'crown'],
        'user' => ['label' => 'Usuario', 'class' => 'primary', 'icon' => 'user']
    ];
    return $roles[$role] ?? ['label' => $role, 'class' => 'secondary', 'icon' => 'user'];
}

function formatShift($shift) {
    $shifts = [
        'group_1' => 'Turno Diurno (8:00 - 15:00)',
        'group_2' => 'Turno Nocturno (15:00 - 02:00)'
    ];
    return $shifts[$shift] ?? $shift;
}

function formatFtpGroup($group) {
    $groups = [
        'reprobados' => 'Reprobados',
        'recursadores' => 'Recursadores'
    ];
    return $groups[$group] ?? $group;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mi Perfil - Sistema RRHH</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body { 
            background-color: #f8f9fa; 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .profile-card { 
            border: none; 
            box-shadow: 0 0 20px rgba(0,0,0,0.1); 
            border-radius: 15px;
        }
        .profile-header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            color: white; 
            border-radius: 15px 15px 0 0;
            padding: 2rem;
            text-align: center;
        }
        .profile-avatar {
            width: 120px;
            height: 120px;
            background: rgba(255,255,255,0.2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1rem;
            font-size: 3rem;
        }
        .info-section {
            padding: 1.5rem;
            border-bottom: 1px solid #e9ecef;
        }
        .info-section:last-child {
            border-bottom: none;
        }
        .info-section h6 {
            color: #667eea;
            font-weight: 600;
            margin-bottom: 1rem;
            text-transform: uppercase;
            font-size: 0.85rem;
            letter-spacing: 0.5px;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0.75rem 0;
            border-bottom: 1px solid #f8f9fa;
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .info-label {
            font-weight: 500;
            color: #495057;
            display: flex;
            align-items: center;
        }
        .info-label i {
            margin-right: 0.5rem;
            width: 16px;
            text-align: center;
        }
        .info-value {
            color: #212529;
            font-weight: 400;
        }
        .salary-value {
            font-weight: 600;
            color: #28a745;
        }
        .btn-edit {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 25px;
            padding: 0.5rem 2rem;
        }
        .btn-edit:hover {
            background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
        }
    </style>
</head>
<body>
    <?php include './shared/navbar.php'; ?>
    
    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-lg-8 col-xl-6">
                <div class="card profile-card">
                    <!-- Header del Perfil -->
                    <div class="profile-header">
                        <div class="profile-avatar">
                            <i class="fas fa-user"></i>
                        </div>
                        <h3 class="mb-1"><?php echo htmlspecialchars($user_data['fullname']); ?></h3>
                        <p class="mb-2 opacity-75"><?php echo htmlspecialchars($user_data['charge']); ?></p>
                        <?php $role_info = formatRole($user_data['role']); ?>
                        <span class="badge bg-<?php echo $role_info['class']; ?> fs-6">
                            <i class="fas fa-<?php echo $role_info['icon']; ?> me-1"></i>
                            <?php echo $role_info['label']; ?>
                        </span>
                    </div>
                    
                    <!-- Información Personal -->
                    <div class="info-section">
                        <h6><i class="fas fa-user me-2"></i>Información Personal</h6>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-id-card text-muted"></i>
                                Nombre Completo
                            </div>
                            <div class="info-value"><?php echo htmlspecialchars($user_data['fullname']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-at text-muted"></i>
                                Usuario
                            </div>
                            <div class="info-value"><?php echo htmlspecialchars($user_data['username']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-envelope text-muted"></i>
                                Correo Electrónico
                            </div>
                            <div class="info-value"><?php echo htmlspecialchars($user_data['email']); ?></div>
                        </div>
                    </div>
                    
                    <!-- Información Laboral -->
                    <div class="info-section">
                        <h6><i class="fas fa-briefcase me-2"></i>Información Laboral</h6>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-building text-muted"></i>
                                Departamento
                            </div>
                            <div class="info-value"><?php echo formatDepartment($user_data['department']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-user-tie text-muted"></i>
                                Cargo
                            </div>
                            <div class="info-value"><?php echo htmlspecialchars($user_data['charge']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-clock text-muted"></i>
                                Turno de Trabajo
                            </div>
                            <div class="info-value"><?php echo formatShift($user_data['shift']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-dollar-sign text-muted"></i>
                                Salario
                            </div>
                            <div class="info-value salary-value">$<?php echo number_format($user_data['salary'], 2); ?></div>
                        </div>
                    </div>
                    
                    <!-- Información del Sistema -->
                    <div class="info-section">
                        <h6><i class="fas fa-cogs me-2"></i>Información del Sistema</h6>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-toggle-on text-muted"></i>
                                Estado de la Cuenta
                            </div>
                            <div class="info-value">
                                <?php $status_info = formatStatus($user_data['status']); ?>
                                <span class="badge bg-<?php echo $status_info['class']; ?>">
                                    <?php echo $status_info['label']; ?>
                                </span>
                            </div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-folder text-muted"></i>
                                Grupo FTP
                            </div>
                            <div class="info-value"><?php echo formatFtpGroup($user_data['ftp_group']); ?></div>
                        </div>
                        
                        <div class="info-item">
                            <div class="info-label">
                                <i class="fas fa-calendar-plus text-muted"></i>
                                Fecha de Creación
                            </div>
                            <div class="info-value"><?php echo date('d/m/Y H:i', strtotime($user_data['created_at'])); ?></div>
                        </div>
                    </div>
                    
                    <!-- Botones de Acción -->
                    <div class="info-section text-center">
                        <div class="d-grid gap-2 d-md-flex justify-content-md-center">

                            <a href="change-password.php" class="btn btn-outline-secondary">
                                <i class="fas fa-key me-2"></i>Cambiar Contraseña
                            </a>
                        </div>
                        <div class="mt-3">
                            <a href="dashboard.php" class="btn btn-link text-decoration-none">
                                <i class="fas fa-arrow-left me-1"></i>Volver al Dashboard
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
