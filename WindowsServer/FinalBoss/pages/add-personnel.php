<?php
session_start();
if (!isset($_SESSION['user']) or $_SESSION['role'] !== 'admin') {
    header("Location: ../index.php");
    exit();
}
require_once '../core/DatabaseManager.php';
if ($_POST) {
    $full_name = $_POST['full_name'];
    $username = $_POST['username'];
    $email = $_POST['email'];
    $position = $_POST['position'];
    $department = $_POST['department'];
    $salary = $_POST['salary'];
    $ftp_group = $_POST['ftp_group'];
    $ftp_permissions = $_POST['ftp_permissions'];
    $docker_type = $_POST['docker_type'];
    $container_name = $_POST['container_name'];
    $container_port = $_POST['container_port'];
    $group_shift = $_POST['group_shift'];
    $dbManager = new DatabaseManager();
    $dbManager->registerUser($full_name, $username, $email, $position, $department, $salary, $group_shift, $ftp_group);
    $dbManager->registerContainer($container_name, $docker_type, $container_port, $username);

}
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crear Usuario - Sistema RRHH</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        .card {
            border: none;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
            border-radius: 10px;
        }

        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px 10px 0 0 !important;
        }

        .section-header {
            background-color: #e9ecef;
            padding: 15px 20px;
            margin: 25px -20px 20px -20px;
            border-left: 4px solid #667eea;
            font-weight: 600;
        }

        .form-check-input:checked {
            background-color: #667eea;
            border-color: #667eea;
        }

        .group-description {
            font-size: 0.85em;
            color: #6c757d;
            margin-top: 8px;
            padding-left: 25px;
            line-height: 1.4;
        }

        .service-card {
            border: 1px solid #dee2e6;
            border-radius: 8px;
            margin-bottom: 20px;
            transition: all 0.3s ease;
        }

        .service-card:hover {
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .service-card-header {
            background-color: #f8f9fa;
            padding: 15px 20px;
            border-bottom: 1px solid #dee2e6;
            border-radius: 8px 8px 0 0;
        }

        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
        }

        .btn-primary:hover {
            background: linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%);
        }

        .salary-input {
            position: relative;
        }

        .salary-input::before {
            content: '$';
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #6c757d;
            font-weight: bold;
        }

        .salary-input input {
            padding-left: 25px;
        }
    </style>
</head>

<body>
    <?php include './shared/navbar.php'; ?>

    <div class="container mt-4">
        <div class="row justify-content-center">
            <div class="col-lg-10">
                <div class="card">
                    <div class="card-header">
                        <h4 class="mb-0">
                            <i class="fas fa-user-plus me-2"></i>Crear Nuevo Usuario
                        </h4>
                        <p class="mb-0 mt-2 opacity-75">Complete la información para crear un nuevo usuario en el sistema</p>
                    </div>
                    <div class="card-body p-4">
                        <form method="POST" onsubmit="" id="createUserForm">

                            <!-- Información Personal -->
                            <div class="section-header">
                                <h5 class="mb-0">
                                    <i class="fas fa-user me-2"></i>Información Personal
                                </h5>
                            </div>

                            <div class="row">
                                <div class="col-md-6 mb-3">
                                    <label for="full_name" class="form-label">
                                        <i class="fas fa-id-card me-1"></i>Nombre Completo*
                                    </label>
                                    <input type="text" class="form-control" id="full_name" name="full_name" required
                                        placeholder="Ingrese el nombre completo">
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="full_name" class="form-label">
                                        <i class="fas fa-id-card me-1"></i>Nombre de Usuario*
                                    </label>
                                    <input type="text" class="form-control" id="username" name="username" required
                                        placeholder="Ingrese el nombre del usuario">
                                </div>
                                <div class="col-md-6 mb-3">
                                    <label for="email" class="form-label">
                                        <i class="fas fa-envelope me-1"></i>Correo Electrónico*
                                    </label>
                                    <input type="email" class="form-control" id="email" name="email" required
                                        placeholder="usuario@empresa.com">
                                </div>
                            </div>

                            <div class="row">
                                <div class="col-md-4 mb-3">
                                    <label for="position" class="form-label">
                                        <i class="fas fa-briefcase me-1"></i>Cargo*
                                    </label>
                                    <input type="text" class="form-control" id="position" name="position" required
                                        placeholder="Ej: Desarrollador Senior">
                                </div>
                                <div class="col-md-4 mb-3">
                                    <label for="department" class="form-label">
                                        <i class="fas fa-building me-1"></i>Departamento*
                                    </label>
                                    <select class="form-select" id="department" name="department" required>
                                        <option value="">Seleccionar departamento</option>
                                        <option value="desarrollo_web">Desarrollo Web</option>
                                        <option value="admin_bd">Administrador de Bases de Datos</option>
                                    </select>
                                </div>
                                <div class="col-md-4 mb-3">
                                    <label for="salary" class="form-label">
                                        <i class="fas fa-dollar-sign me-1"></i>Salario*
                                    </label>
                                    <div class="salary-input">
                                        <input type="number" class="form-control" id="salary" name="salary" required
                                            min="0" step=any>
                                    </div>
                                </div>
                            </div>

                            <!-- Configuración de Servicios -->
                            <div class="section-header">
                                <h5 class="mb-0">
                                    <i class="fas fa-cogs me-2"></i>Configuración de Servicios
                                </h5>
                            </div>

                            <!-- Selección de Grupo -->
                            <div class="service-card">
                                <div class="service-card-header">
                                    <h6 class="mb-0">
                                        <i class="fas fa-users me-2"></i>Selección de Grupo de Usuario
                                    </h6>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-check p-3 border rounded">
                                                <input class="form-check-input" type="radio" name="group_shift"
                                                    id="group1" value="group_1" checked>
                                                <label class="form-check-label fw-bold" for="group1">
                                                    <i class="fas fa-sun me-2 text-warning"></i>Grupo 1 - Turno Diurno
                                                </label>
                                                <div class="group-description">
                                                    <i class="fas fa-clock me-1"></i> Solo puede iniciar sesión de 8:00 a 15:00<br>
                                                    <i class="fas fa-hdd me-1"></i> Solo puede almacenar archivos de 5MB<br>
                                                    <i class="fas fa-edit me-1"></i> Solo puede usar el bloc de notas
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-check p-3 border rounded">
                                                <input class="form-check-input" type="radio" name="group_shift"
                                                    id="group2" value="group_2">
                                                <label class="form-check-label fw-bold" for="group2">
                                                    <i class="fas fa-moon me-2 text-info"></i>Grupo 2 - Turno Nocturno
                                                </label>
                                                <div class="group-description">
                                                    <i class="fas fa-clock me-1"></i> Solo puede iniciar sesión de 15:00 a 02:00<br>
                                                    <i class="fas fa-desktop me-1"></i> Puede acceder a todos los programas excepto el bloc de notas<br>
                                                    <i class="fas fa-hdd me-1"></i> Solo puede almacenar archivos de 10MB
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>


                            <!-- Asignación de Grupo FTP -->
                            <div class="service-card">
                                <div class="service-card-header">
                                    <h6 class="mb-0">
                                        <i class="fas fa-folder me-2"></i>Asignación de Grupo FTP
                                    </h6>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label for="ftp_group" class="form-label">
                                                <i class="fas fa-server me-1"></i>Grupo FTP*
                                            </label>
                                            <select class="form-select" id="ftp_group" name="ftp_group" required>
                                                <option value="">Seleccionar grupo FTP</option>
                                                <option value="reprobados">Reprobados</option>
                                                <option value="recursados">Recursadores</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label for="ftp_permissions" class="form-label">
                                                <i class="fas fa-key me-1"></i>Permisos FTP
                                            </label>
                                            <select class="form-select" id="ftp_permissions" name="ftp_permissions">
                                                <option value="read_write">Lectura y Escritura</option>
                                                <option value="read_only">Solo Lectura</option>
                                                <option value="write_only">Solo Escritura</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Crear Contenedor Docker -->
                            <div class="service-card">
                                <div class="service-card-header">
                                    <h6 class="mb-0">
                                        <i class="fab fa-docker me-2"></i>Crear Contenedor Docker
                                    </h6>
                                </div>
                                <div class="card-body">
                                    <div class="mb-4">
                                        <label class="form-label fw-bold">Tipo de Contenedor*</label>
                                        <div class="row">
                                            <div class="col-md-6">
                                                <div class="form-check p-3 border rounded">
                                                    <input class="form-check-input" type="radio" name="docker_type"
                                                        id="docker_apache" value="web" checked onchange="toggleDockerFields()">
                                                    <label class="form-check-label fw-bold" for="docker_apache">
                                                        <i class="fas fa-server me-2 text-success"></i>Apache Web Server
                                                    </label>
                                                    <div class="group-description">
                                                        Servidor web para aplicaciones PHP, HTML y JavaScript
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="col-md-6">
                                                <div class="form-check p-3 border rounded">
                                                    <input class="form-check-input" type="radio" name="docker_type"
                                                        id="docker_postgres" value="postgres" onchange="toggleDockerFields()">
                                                    <label class="form-check-label fw-bold" for="docker_postgres">
                                                        <i class="fas fa-database me-2 text-primary"></i>PostgreSQL Database
                                                    </label>
                                                    <div class="group-description">
                                                        Base de datos relacional avanzada con soporte completo SQL
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label for="container_name" class="form-label">
                                                <i class="fas fa-tag me-1"></i>Nombre del Contenedor*
                                            </label>
                                            <input type="text" class="form-control" id="container_name" name="container_name" required
                                                placeholder="Ej: usuario_apache_container">
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label for="container_port" class="form-label">
                                                <i class="fas fa-plug me-1"></i>Puerto*
                                            </label>
                                            <input type="number" class="form-control" id="container_port" name="container_port"
                                                required value="8080" min="1024" max="65535">
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Configurar PostgreSQL con Túnel SSH -->
                            <div class="service-card" id="postgres_ssh_config" style="display: none;">
                                <div class="service-card-header">
                                    <h6 class="mb-0">
                                        <i class="fas fa-shield-alt me-2"></i>Configurar PostgreSQL con Túnel SSH
                                    </h6>
                                </div>
                                <div class="card-body">
                                    <div class="alert alert-info">
                                        <i class="fas fa-info-circle me-2"></i>
                                        <strong>Seguridad Avanzada:</strong> Esta configuración permitirá acceso a PostgreSQL
                                        únicamente a través de túnel SSH, proporcionando una capa adicional de seguridad.
                                    </div>
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label for="ssh_port" class="form-label">
                                                <i class="fas fa-terminal me-1"></i>Puerto SSH
                                            </label>
                                            <input type="number" class="form-control" id="ssh_port" name="ssh_port"
                                                value="22" min="1" max="65535">
                                            <div class="form-text">Puerto estándar SSH: 22</div>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label for="postgres_port" class="form-label">
                                                <i class="fas fa-database me-1"></i>Puerto PostgreSQL
                                            </label>
                                            <input type="number" class="form-control" id="postgres_port" name="postgres_port"
                                                value="5432" min="1" max="65535">
                                            <div class="form-text">Puerto estándar PostgreSQL: 5432</div>
                                        </div>
                                    </div>
                                    <div class="row">
                                        <div class="col-md-12 mb-3">
                                            <label for="ssh_key_type" class="form-label">
                                                <i class="fas fa-key me-1"></i>Tipo de Clave SSH
                                            </label>
                                            <select class="form-select" id="ssh_key_type" name="ssh_key_type">
                                                <option value="rsa">RSA (Recomendado)</option>
                                                <option value="ed25519">ED25519 (Más Seguro)</option>
                                                <option value="ecdsa">ECDSA</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Botones de Acción -->
                            <div class="d-flex justify-content-between align-items-center mt-4 pt-3 border-top">
                                <div>
                                    <small class="text-muted">
                                        <i class="fas fa-info-circle me-1"></i>
                                        Los campos marcados con* son obligatorios
                                    </small>
                                </div>
                                <div>
                                    <a href="/pages/personnel-management.php" class="btn btn-secondary me-2">
                                        <i class="fas fa-times me-2"></i>Cancelar
                                    </a>
                                    <button type="submit" class="btn btn-primary">
                                        <i class="fas fa-save me-2"></i>Crear Usuario
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Auto-generar nombre de contenedor basado en nombre completo
        document.getElementById('full_name').addEventListener('input', function() {
            const fullName = this.value.toLowerCase().trim();
            if (fullName) {
                const containerName = fullName.replace(/\s+/g, '_') + '_container';
                document.getElementById('container_name').value = containerName;
            }
        });

        // Función para mostrar/ocultar configuración de PostgreSQL SSH
        function toggleDockerFields() {
            const postgresSelected = document.getElementById('docker_postgres').checked;
            const postgresConfig = document.getElementById('postgres_ssh_config');
            const containerPort = document.getElementById('container_port');

            if (postgresSelected) {
                postgresConfig.style.display = 'block';
                containerPort.value = '5432';
            } else {
                postgresConfig.style.display = 'none';
                containerPort.value = '8080';
            }
        }

        // Validación del formulario
        document.getElementById('createUserForm').addEventListener('submit', function(e) {
            const requiredFields = this.querySelectorAll('[required]');
            let isValid = true;

            requiredFields.forEach(field => {
                if (!field.value.trim()) {
                    field.classList.add('is-invalid');
                    isValid = false;
                } else {
                    field.classList.remove('is-invalid');
                }
            });

            if (!isValid) {
                e.preventDefault();
                alert('Por favor, complete todos los campos obligatorios.');
            }
        });

        // Inicializar estado al cargar la página
        document.addEventListener('DOMContentLoaded', function() {
            toggleDockerFields();
        });

        // Formatear salario despues de 3 segundos de la entrada
        document.getElementById('salary').addEventListener('blur', function() {
            const value = parseFloat(this.value);
            if (!isNaN(value)) {
                this.value = value.toFixed(2);
            }
        });
    </script>
</body>

</html>