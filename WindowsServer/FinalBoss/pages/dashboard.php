<?php
require_once __DIR__ . '\..\core\DatabaseManager.php';
require_once __DIR__ . '\..\core\server-manager.php';
session_start();
if (!isset($_SESSION['user'])) {
    header("Location: index.php");
    exit();
}
$sManager = new ServerManager();
echo $sManager->testeillo();
$dbManager = new DatabaseManager();
$user_name = $_SESSION['user'];
$user_role = $_SESSION['role'];
// Simulación de datos (en producción vendrían de la base de datos)
if ($user_role === 'admin') {
    $stats = $dbManager->getStats();

    $usersAddedToday = $dbManager->getRecentActivity();
} else {
    // Datos específicos del usuario
    $user_stats = [
        'my_services' => 4,
        'active_containers' => 2,
        'ftp_usage' => '2.3 GB',
        'last_login' => '2024-01-15 09:30:00'
    ];

    $my_services = [
        ['name' => 'Active Directory', 'status' => 'active', 'group' => 'Grupo 1'],
        ['name' => 'Cuenta FTP', 'status' => 'active', 'group' => 'Reprobados'],
        ['name' => 'Contenedor Apache', 'status' => 'active', 'port' => '8080'],
        ['name' => 'Correo Corporativo', 'status' => 'active', 'email' => $user_name . '@empresa.com']
    ];

    $my_activity = [
        ['action' => 'Inicio de sesión', 'time' => 'Hace 30 minutos'],
        ['action' => 'Acceso a contenedor Docker', 'time' => 'Hace 2 horas'],
        ['action' => 'Cambio de contraseña', 'time' => 'Hace 3 días'],
        ['action' => 'Descarga de archivos FTP', 'time' => 'Hace 1 semana']
    ];
}
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Sistema RRHH</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }

        .card {
            border: none;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
        }

        .stat-card {
            transition: transform 0.2s;
        }

        .stat-card:hover {
            transform: translateY(-5px);
        }

        .stat-icon {
            font-size: 2.5rem;
            opacity: 0.8;
        }

        .service-status {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
        }

        .status-active {
            background-color: #28a745;
        }

        .status-inactive {
            background-color: #dc3545;
        }

        .status-warning {
            background-color: #ffc107;
        }
    </style>
</head>

<body>
    <?php include './shared/navbar.php'; ?>


    <div class="container-fluid mt-4">
        <div class="row">
            <div class="col-12">
                <h2 class="mb-1">
                    <?php if ($user_role === 'admin'): ?>
                        Dashboard Administrativo
                    <?php else: ?>
                        Mi Panel Personal
                    <?php endif; ?>
                </h2>
                <p class="text-muted mb-4">
                    Bienvenido/a, <strong><?php echo htmlspecialchars($user_name); ?></strong>
                    <?php if ($user_role === 'user'): ?>
                        - Aquí puedes ver tus servicios y actividad
                    <?php else: ?>
                        - Panel de control del sistema RRHH
                    <?php endif; ?>
                </p>
            </div>
        </div>

        <?php if ($user_role === 'admin'): ?>
            <div class="row mb-4">
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-primary text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Personal Total</h5>
                                <h2 class="mb-0"><?php echo $stats['total_personnel']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-users"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-success text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Usuarios Activos</h5>
                                <h2 class="mb-0"><?php echo $stats['active_users']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-user-check"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-warning text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Contenedores Activos</h5>
                                <h2 class="mb-0"><?php echo $stats['active_containers']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-cogs"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-info text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Nuevos Este Mes</h5>
                                <h2 class="mb-0"><?php echo $stats['new_this_month']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-user-plus"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Acciones Rápidas Admin -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-tools me-2"></i>Herramientas Administrativas</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 mb-3">
                                    <a href="./add-personnel.php" class="btn btn-primary w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-user-plus fa-2x mb-2"></i>
                                        <span>Agregar Personal</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="personnel-management.php" class="btn btn-success w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-users-cog fa-2x mb-2"></i>
                                        <span>Gestionar Personal</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="services-management.php" class="btn btn-warning w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-server fa-2x mb-2"></i>
                                        <span>Modificar Servicios</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="system-reports.php" class="btn btn-info w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-chart-line fa-2x mb-2"></i>
                                        <span>Reportes del Sistema</span>
                                    </a>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-3 mb-3">
                                    <a href="backup-management.php" class="btn btn-secondary w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-database fa-2x mb-2"></i>
                                        <span>Gestión de Backups</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="system-logs.php" class="btn btn-dark w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-file-alt fa-2x mb-2"></i>
                                        <span>Logs del Sistema</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="security-settings.php" class="btn btn-danger w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-shield-alt fa-2x mb-2"></i>
                                        <span>Configuración de Seguridad</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="bulk-operations.php" class="btn btn-outline-primary w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-tasks fa-2x mb-2"></i>
                                        <span>Operaciones Masivas</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Actividad Reciente Admin -->
            <div class="row">
                <div class="col-md-8">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-history me-2"></i>Usuarios Agregados hoy</h5>
                        </div>
                        <div class="card-body">
                            <div class="list-group list-group-flush">
                                <?php foreach ($usersAddedToday as $user): ?>
                                    <div class="list-group-item d-flex align-items-center">
                                        <div class="me-3">
                                            <?php
                                            $icon_class = 'fas fa-user-plus';
                                            $icon_color = 'text-success';
                                            $message = "fue agregado al sistema";
                                            ?>
                                            <i class="<?php echo $icon_class . ' ' . $icon_color; ?>"></i>
                                        </div>
                                        <div class="flex-grow-1">
                                            <strong><?php echo htmlspecialchars($user['fullname']); ?></strong> <?php echo $message; ?>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-exclamation-triangle me-2"></i>Alertas del Sistema</h5>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-danger">
                                <i class="fas fa-exclamation-circle me-2"></i>
                                <strong><?php $stats['inactive_containers'] ?></strong> contenedores Docker inactivos
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        <?php else: ?>
            <!-- VISTA USUARIO -->

            <!-- Estadísticas del Usuario -->
            <div class="row mb-4">
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-primary text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Mis Servicios</h5>
                                <h2 class="mb-0"><?php echo $user_stats['my_services']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-cogs"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-success text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Contenedores Activos</h5>
                                <h2 class="mb-0"><?php echo $user_stats['active_containers']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fab fa-docker"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-warning text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Uso FTP</h5>
                                <h2 class="mb-0"><?php echo $user_stats['ftp_usage']; ?></h2>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-folder"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card stat-card bg-info text-white">
                        <div class="card-body d-flex align-items-center">
                            <div class="flex-grow-1">
                                <h5 class="card-title">Último Acceso</h5>
                                <h6 class="mb-0"><?php echo date('d/m H:i', strtotime($user_stats['last_login'])); ?></h6>
                            </div>
                            <div class="stat-icon">
                                <i class="fas fa-clock"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Acciones Rápidas Usuario -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-user-cog me-2"></i>Mis Herramientas</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 mb-3">
                                    <a href="change-password.php" class="btn btn-primary w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-key fa-2x mb-2"></i>
                                        <span>Cambiar Contraseña</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="my-services.php" class="btn btn-success w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-list fa-2x mb-2"></i>
                                        <span>Ver Mis Servicios</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="ftp-manager.php" class="btn btn-warning w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-folder-open fa-2x mb-2"></i>
                                        <span>Gestor FTP</span>
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="docker-console.php" class="btn btn-info w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fab fa-docker fa-2x mb-2"></i>
                                        <span>Consola Docker</span>
                                    </a>
                                </div>
                            </div>
                            <div class="row">

                                <div class="col-md-4 mb-3">
                                    <a href="/pages/profile.php" class="btn btn-outline-primary w-100 h-100 d-flex flex-column align-items-center justify-content-center">
                                        <i class="fas fa-user-edit fa-2x mb-2"></i>
                                        <span>Mi Perfil</span>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Mis Servicios y Actividad -->
            <div class="row">
                <div class="col-md-8">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-server me-2"></i>Estado de Mis Servicios</h5>
                        </div>
                        <div class="card-body">
                            <div class="list-group list-group-flush">
                                <?php foreach ($my_services as $service): ?>
                                    <div class="list-group-item d-flex align-items-center justify-content-between">
                                        <div class="d-flex align-items-center">
                                            <span class="service-status status-<?php echo $service['status']; ?>"></span>
                                            <div>
                                                <strong><?php echo $service['name']; ?></strong>
                                                <small class="text-muted d-block">
                                                    <?php
                                                    if (isset($service['group'])) echo "Grupo: " . $service['group'];
                                                    if (isset($service['port'])) echo "Puerto: " . $service['port'];
                                                    if (isset($service['email'])) echo "Email: " . $service['email'];
                                                    ?>
                                                </small>
                                            </div>
                                        </div>
                                        <span class="badge bg-<?php echo $service['status'] === 'active' ? 'success' : 'danger'; ?>">
                                            <?php echo $service['status'] === 'active' ? 'Activo' : 'Inactivo'; ?>
                                        </span>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fas fa-history me-2"></i>Mi Actividad Reciente</h5>
                        </div>
                        <div class="card-body">
                            <div class="list-group list-group-flush">
                                <?php foreach ($my_activity as $activity): ?>
                                    <div class="list-group-item">
                                        <div class="d-flex align-items-center">
                                            <i class="fas fa-circle text-primary me-2" style="font-size: 0.5rem;"></i>
                                            <div>
                                                <div><?php echo $activity['action']; ?></div>
                                                <small class="text-muted"><?php echo $activity['time']; ?></small>
                                            </div>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        </div>
                    </div>

                    <!-- Información Adicional -->
                    <div class="card mt-3">
                        <div class="card-header">
                            <h6 class="mb-0"><i class="fas fa-info-circle me-2"></i>Información Útil</h6>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-info">
                                <small>
                                    <i class="fas fa-lightbulb me-1"></i>
                                    <strong>Tip:</strong> Recuerda cambiar tu contraseña regularmente para mantener tu cuenta segura.
                                </small>
                            </div>
                            <div class="alert alert-warning">
                                <small>
                                    <i class="fas fa-exclamation-triangle me-1"></i>
                                    Tu cuota FTP está al 76% de capacidad.
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        <?php endif; ?>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>