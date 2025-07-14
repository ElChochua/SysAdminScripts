<?php
// pages/dashboard.php

$message = '';
$error = '';

// --- DATOS ESTÁTICOS PARA SIMULACIÓN ---
$totalEmpleados = 12;
$apacheRunning = true;
$apacheExists = true;
$postgresRunning = false;
$postgresExists = true;
?>

<!-- Estilos personalizados en la misma página -->
<style>
.dashboard-card {
    background: #fff;
    border-radius: 0.5rem;
    box-shadow: 0 2px 8px rgba(0,0,0,0.07);
    padding: 2rem 1rem 1.5rem 1rem;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    min-height: 220px;
    transition: box-shadow 0.2s;
}
.dashboard-card:hover {
    box-shadow: 0 4px 16px rgba(0,0,0,0.13);
}
.card-icon {
    font-size: 2.5rem;
    color: #0d6efd;
    margin-bottom: 1rem;
}
.table th, .table td {
    vertical-align: middle;
}
.btn[disabled] {
    pointer-events: none;
    opacity: 0.6;
}
.modal-title i {
    margin-right: 0.5rem;
}
</style>

<div class="row">
    <div class="col-12">
        <h1 class="mb-4">
            <i class="fas fa-tachometer-alt"></i> Dashboard
        </h1>
    </div>
</div>

<div class="row">
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="dashboard-card text-center h-100">
            <div class="card-icon"><i class="fas fa-user-plus"></i></div>
            <h4>Nuevo Empleado (DB)</h4>
            <p>Agregar a la base de datos local</p>
            <a href="personal_form.php" class="btn btn-success btn-sm mt-auto"><i class="fas fa-plus"></i> Agregar</a>
        </div>
    </div>
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="dashboard-card text-center h-100">
            <div class="card-icon"><i class="fas fa-server"></i></div>
            <h4>Configurar FTP</h4>
            <p>Crear sitio FTP con auth de AD</p>
            <button type="button" class="btn btn-secondary btn-sm mt-auto" data-bs-toggle="modal" data-bs-target="#configurarFTPModal">
                <i class="fas fa-cogs"></i> Configurar Servidor
            </button>
        </div>
    </div>
    <div class="col-xl-3 col-md-6 mb-4">
        <div class="dashboard-card text-center h-100">
            <div class="card-icon"><i class="fas fa-users"></i></div>
            <h4><?php echo $totalEmpleados; ?></h4>
            <p>Total de Empleados</p>
            <a href="personal.php" class="btn btn-primary btn-sm mt-auto"><i class="fas fa-eye"></i> Ver Todos</a>
        </div>
    </div>
</div>

<?php if ($message): ?>
    <div class="alert alert-success"><?php echo $message; ?></div>
<?php endif; ?>
<?php if ($error): ?>
    <div class="alert alert-danger"><?php echo $error; ?></div>
<?php endif; ?>

<div class="row mt-4">
    <div class="col-12">
        <div class="card">
            <div class="card-header">
                <h4><i class="fas fa-cubes"></i> Gestión de Contenedores Docker</h4>
            </div>
            <div class="card-body">

                <form method="POST" class="row g-3 align-items-center mb-4">
                    <div class="col-auto">
                         <label for="docker_service" class="visually-hidden">Servicio Docker</label>
                    </div>
                    <div class="col-auto">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="docker_service" id="apache" value="apache" required>
                            <label class="form-check-label" for="apache">Apache</label>
                        </div>
                    </div>
                    <div class="col-auto">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="docker_service" id="postgres" value="postgres" required>
                            <label class="form-check-label" for="postgres">PostgreSQL</label>
                        </div>
                    </div>
                    <div class="col-auto">
                        <button type="submit" name="action" value="start" class="btn btn-primary">Levantar Contenedor</button>
                    </div>
                </form>

                <h5>Estado Actual de Contenedores:</h5>
                <table class="table table-bordered">
                    <thead>
                        <tr>
                            <th>Contenedor</th>
                            <th>Estado</th>
                            <th>Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>mi_apache_container</td>
                            <td>
                                <?php
                                    if (!$apacheExists) echo '<span class="badge bg-secondary">No existe</span>';
                                    elseif ($apacheRunning) echo '<span class="badge bg-success">En ejecución</span>';
                                    else echo '<span class="badge bg-warning text-dark">Detenido</span>';
                                ?>
                            </td>
                            <td>
                                <form method="POST" style="display:inline-block;">
                                    <input type="hidden" name="container_name" value="mi_apache_container">
                                    <button type="submit" name="action" value="stop" class="btn btn-sm btn-warning" <?php echo $apacheRunning ? '' : 'disabled'; ?>>Detener</button>
                                </form>
                                <form method="POST" style="display:inline-block;">
                                    <input type="hidden" name="container_name" value="mi_apache_container">
                                    <button type="submit" name="action" value="remove" class="btn btn-sm btn-danger" <?php echo $apacheExists ? '' : 'disabled'; ?>>Eliminar</button>
                                </form>
                            </td>
                        </tr>
                        <tr>
                            <td>mi_postgres_container</td>
                            <td>
                                <?php
                                    if (!$postgresExists) echo '<span class="badge bg-secondary">No existe</span>';
                                    elseif ($postgresRunning) echo '<span class="badge bg-success">En ejecución</span>';
                                    else echo '<span class="badge bg-warning text-dark">Detenido</span>';
                                ?>
                            </td>
                            <td>
                                <form method="POST" style="display:inline-block;">
                                    <input type="hidden" name="container_name" value="mi_postgres_container">
                                    <button type="submit" name="action" value="stop" class="btn btn-sm btn-warning" <?php echo $postgresRunning ? '' : 'disabled'; ?>>Detener</button>
                                </form>
                                <form method="POST" style="display:inline-block;">
                                    <input type="hidden" name="container_name" value="mi_postgres_container">
                                    <button type="submit" name="action" value="remove" class="btn btn-sm btn-danger" <?php echo $postgresExists ? '' : 'disabled'; ?>>Eliminar</button>
                                </form>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="crearUsuarioADModal" tabindex="-1" aria-labelledby="crearUsuarioADModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="crearUsuarioADModalLabel"><i class="fas fa-user-tie"></i> Crear Nuevo Usuario en Active Directory</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form action="dashboard.php" method="POST">
        <div class="modal-body">
            <p class="text-muted mb-4">Completa el formulario para registrar un nuevo usuario en AD.</p>
            <input type="hidden" name="action" value="create_ad_user">
            <div class="mb-3">
                <label for="ad_nombre_usuario" class="form-label">Nombre de Usuario (SamAccountName)</label>
                <input type="text" class="form-control" id="ad_nombre_usuario" name="nombre_usuario" placeholder="ej. juan.perez" required>
            </div>
            <div class="mb-3">
                <label for="ad_nombre_completo" class="form-label">Nombre Completo</label>
                <input type="text" class="form-control" id="ad_nombre_completo" name="nombre_completo" placeholder="ej. Juan Pérez" required>
            </div>
            <div class="mb-3">
                <label for="ad_email" class="form-label">Correo Electrónico</label>
                <input type="email" class="form-control" id="ad_email" name="email" placeholder="ej. juan.perez@dominio.com" required>
            </div>
            <div class="mb-3">
                <label for="ad_tipo_usuario" class="form-label">Tipo de Usuario</label>
                <select class="form-select" id="ad_tipo_usuario" name="tipo_usuario" required>
                    <option value="cuates">Cuates</option>
                    <option value="no cuates">No Cuates</option>
                </select>
            </div>
            <div class="mb-3">
                <label for="ad_password" class="form-label">Contraseña</label>
                <input type="password" class="form-control" id="ad_password" name="password" placeholder="••••••••" required>
            </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-primary"><i class="fas fa-plus-circle"></i> Crear Usuario</button>
        </div>
      </form>
    </div>
  </div>
</div>

<div class="modal fade" id="configurarFTPModal" tabindex="-1" aria-labelledby="configurarFTPModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="configurarFTPModalLabel"><i class="fas fa-server"></i> Configurar Servidor FTP con Active Directory</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form action="dashboard.php" method="POST">
        <div class="modal-body">
            <p class="text-muted mb-4">Completa el formulario para configurar un nuevo sitio FTP.</p>
            <input type="hidden" name="action" value="configure_ftp">
            <div class="mb-3">
                <label for="ftp_sitio_ftp" class="form-label">Nombre del Sitio FTP</label>
                <input type="text" class="form-control" id="ftp_sitio_ftp" name="sitio_ftp" placeholder="ej. MiSitioFTP" value="Default FTP Site" required>
            </div>
            <div class="mb-3">
                <label for="ftp_ruta_ftp" class="form-label">Ruta Física (Directorio Raíz)</label>
                <input type="text" class="form-control" id="ftp_ruta_ftp" name="ruta_ftp" placeholder="ej. C:\ftp_root" value="C:\Users\Administrator\Documents\ftp_users" required>
            </div>
            <div class="mb-3">
                <label for="ftp_puerto_ftp" class="form-label">Puerto (Opcional)</label>
                <input type="number" class="form-control" id="ftp_puerto_ftp" name="puerto_ftp" placeholder="Dejar en blanco para usar el puerto 21">
            </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancelar</button>
          <button type="submit" class="btn btn-primary"><i class="fas fa-cogs"></i> Configurar Ahora</button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once '../includes/footer.php'; ?>
