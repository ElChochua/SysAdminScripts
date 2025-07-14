<?php
require_once __DIR__ . '\..\core\DatabaseManager.php';
$dbManager = new DatabaseManager();
if($_GET && isset($_GET['id'])) {
    $userId = $_GET['id'];
    $dbManager->deactivateUserById($userId);
    header("Location: /pages/personnel-management.php");
    exit();
} else {
    echo "ID de usuario no proporcionado.";
}
?>