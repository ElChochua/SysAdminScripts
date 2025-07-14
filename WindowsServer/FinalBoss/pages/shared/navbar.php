<?php
$username = $_SESSION['user'] ?? 'Invitado';
?>
<nav class="navbar navbar-expand-lg navbar-dark" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
    <div class="container-fluid">
        <a class="navbar-brand" href="/pages/dashboard.php">
            <i class="fas fa-users me-2"></i>Sistema RRHH
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav me-auto">
                <li class="nav-item">
                    <a class="nav-link" href="/pages/dashboard.php">
                        <i class="fas fa-tachometer-alt me-1"></i>Dashboard
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/pages/personnel-management.php">
                        <i class="fas fa-users me-1"></i>Personal
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/pages/services.php">
                        <i class="fas fa-cogs me-1"></i>Servicios
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="/pages/reports.php">
                        <i class="fas fa-chart-bar me-1"></i>Reportes
                    </a>
                </li>
            </ul>
            <ul class="navbar-nav">
                <li class="nav-item dropdown">
                    <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
                        <i class="fas fa-user me-1"></i><?php echo htmlspecialchars($username) ?>
                    </a>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="/pages/profile.php">
                            <i class="fas fa-user-edit me-2"></i>Mi Perfil
                        </a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="/pages/logout.php">
                            <i class="fas fa-sign-out-alt me-2"></i>Cerrar Sesión
                        </a></li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</nav>
