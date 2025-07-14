<?php
session_start();
require_once __DIR__ . '\..\core\DatabaseManager.php';
if (!isset($_SESSION['user']) or $_SESSION['role'] !== 'admin') {
    header("Location: ./dashboard.php");
    exit();
}
$dbManager = new DatabaseManager();
$personnelList = $dbManager->getAllUsers();
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestión de Personal - Sistema RRHH</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/1.13.4/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #f8f9fa;
        }

        .card {
            border: none;
            box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
        }

        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }

        .btn-action {
            margin: 0 2px;
        }
    </style>
</head>

<body>
    <?php include './shared/navbar.php'; ?>

    <div class="container-fluid mt-4">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="mb-0">
                    <i class="fas fa-users me-2"></i>Gestión de Personal
                </h4>
                <a href="/pages/add-personnel.php" class="btn btn-light">
                    <i class="fas fa-plus me-2"></i>Agregar Personal
                </a>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table id="personnelTable" class="table table-striped table-hover">
                        <thead class="table-dark">
                            <tr>
                                <th>ID</th>
                                <th>Nombre Completo</th>
                                <th>Email</th>
                                <th>Departamento</th>
                                <th>Cargo</th>
                                <th>Estado</th>
                                <th>Fecha Ingreso</th>
                                <th>Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($personnelList as $person): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($person['ID']); ?></td>
                                    <td><?php echo htmlspecialchars($person['fullname']); ?></td>
                                    <td><?php echo htmlspecialchars($person['email']); ?></td>
                                    <td><?php echo htmlspecialchars($person['department']); ?></td>
                                    <td><?php echo htmlspecialchars($person['charge']); ?></td>
                                    <td><?php echo htmlspecialchars($person['status']); ?></td>
                                    <td><?php echo htmlspecialchars(date('d-m-Y', strtotime($person['created_at']))); ?></td>
                                    <td class="text-center">
                                        <a href="/pages/edit-personnel.php?id=<?php echo $person['ID']; ?>" class="btn btn-sm btn-primary btn-action">
                                            <i class="fas fa-edit"></i> Editar
                                        </a>
                                        <a href="/pages/deactivate-user.php?id=<?php echo $person['ID']; ?>" class="btn btn-sm btn-danger btn-action">
                                            <i class="fas fa-trash"></i> Desactivar
                                        </a>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/dataTables.bootstrap5.min.js"></script>
    <script>
        $(document).ready(function() {
            $('#personnelTable').DataTable({
                language: {
                    url: '//cdn.datatables.net/plug-ins/1.13.4/i18n/es-ES.json'
                }
            });
        });
    </script>
</body>

</html>