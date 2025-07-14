<?php
require_once __DIR__ . '\MailManager.php';
class DatabaseManager
{
    private $host = "localhost";
    private $user = "root";
    private $password = "admin";
    private $database = "finalboss";
    public $connection;

    public function getConnection()
    {
        if ($this->connection == null) {
            try {
                $this->connection = new PDO("mysql:host={$this->host};dbname={$this->database}", $this->user, $this->password);
                $this->connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            } catch (PDOException $e) {
                echo "Connection failed: " . $e->getMessage();
                return null;
            }
        }
        return $this->connection;
    }
    public function registerUser($fullName, $username, $email, $department, $charge, $salary, $shift, $ftp_group)
    {
        $connection = $this->getConnection();
        if (!$this->userExists($username)) {
            $pepper = "dondecaemosgente";
            $randomPassword = bin2hex(random_bytes(8));
            $peperedPass = hash_hmac("sha256", $randomPassword, $pepper);
            $hashedPassword = password_hash($peperedPass, PASSWORD_DEFAULT);
            $html = file_get_contents("../pages/shared/html-template-format.html");
            $html = str_replace("[FULL_NAME]", $fullName, $html);
            $html = str_replace("[USERNAME]", $username, $html);
            $html = str_replace("[PASSWORD]", $randomPassword, $html);
            $query = "INSERT INTO users (username, fullname, department, charge, password, email, salary, created_at, shift, ftp_group) 
                  VALUES (:username, :fullName, :department, :charge, :password, :email, :salary, NOW(), :shift, :ftp_group)";
            $stmt = $connection->prepare($query);
            $stmt->bindParam(':username', $username);
            $stmt->bindParam(':fullName', $fullName);
            $stmt->bindParam(':department', $department);
            $stmt->bindParam(':charge', $charge);
            $stmt->bindParam(':password', $hashedPassword);
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':salary', $salary);
            $stmt->bindParam(':shift', $shift);
            $stmt->bindParam(':ftp_group', $ftp_group);
            try {
                $stmt->execute();
                $mailManager = new MailManager();
                $mailManager->sendMail($email, "Bienvenido a Reprobados.com", $html);
                return true;
            } catch (PDOException $e) {
                echo "Error al registrar el usuario: " . $e->getMessage();
                return false;
            }
            return false;
        }
    }
    public function registerContainer($containerName, $containerType, $containerPort, $containerOwner)
    {
        $connection = $this->getConnection();
        $query = "INSERT INTO containers (container_name, container_type, container_port, container_owner, container_image) 
                  VALUES (:containerName, :containerType, :containerPort, :container_owner, :container_image)";
        if ($containerType == "web") {
            $containerImage = "httpd:2.4";
        } else {
            $containerImage = "postgres:latest";
        }
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':containerName', $containerName);
        $stmt->bindParam(':containerType', $containerType);
        $stmt->bindParam(':containerPort', $containerPort);
        $stmt->bindParam(':container_owner', $containerOwner);
        $stmt->bindParam(':container_image', $containerImage);
        if (!$this->containerExists($containerName)) {
            try {
                $stmt->execute();
                return true;
            } catch (PDOException $e) {
                echo "Error al registrar el contenedor: " . $e->getMessage();
                return false;
            }
        }
    }
    public function containerExists($containerName)
    {
        $connection = $this->getConnection();
        $query = "SELECT COUNT(*) FROM containers WHERE container_name = :containerName";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':containerName', $containerName);
        $stmt->execute();
        return $stmt->fetchColumn() > 0;
    }
    public function getUserByUsername($username)
    {
        $connection = $this->getConnection();
        $query = "SELECT * FROM users WHERE username = :username";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    public function userExists($username)
    {
        $connection = $this->getConnection();
        $query = "SELECT COUNT(*) FROM users WHERE username = :username";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        return $stmt->fetchColumn() > 0;
    }
    public function getStats()
    {
        $stats = [];
        $connection = $this->getConnection();
        $query = "SELECT COUNT(*) as total_personnel FROM users";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        $stats['total_personnel'] = $stmt->fetchColumn();
        $query = "SELECT COUNT(*) as active_users FROM users WHERE status = 'active'";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        $stats['active_users'] = $stmt->fetchColumn();
        $query = "SELECT COUNT(*) as active_containers FROM containers WHERE container_status = 'running'";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        $stats['active_containers'] = $stmt->fetchColumn();
        #New this month
        $query = "SELECT COUNT(*) as new_this_month FROM users WHERE MONTH(created_at) = MONTH(CURRENT_DATE()) AND YEAR(created_at) = YEAR(CURRENT_DATE())";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        $stats['new_this_month'] = $stmt->fetchColumn();
        $query = "SELECT COUNT(*) as inactive_containers FROM containers WHERE container_status = 'stopped' or container_status = 'inactive'";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        $stats['inactive_containers'] = $stmt->fetchColumn();
        #return stats
        return $stats;
    }
    public function updatePassword($username, $currentPassword, $newPassword)
    {
        if ($this->verifyPassword($username, $currentPassword)) {
            $connection = $this->getConnection();
            $html = file_get_contents("../pages/shared/password-changed-notification.html");
            $html = str_replace("[USERNAME]", $username, $html);
            $html = str_replace("[TODAY_DATE]", date("Y-m-d"), $html);
            $userMail = $this->getEmailByUsername($username);
            $pepper = "dondecaemosgente";
            $peperedPass = hash_hmac("sha256", $newPassword, $pepper);
            $hashedPassword = password_hash($peperedPass, PASSWORD_DEFAULT);
            $query = "UPDATE users SET password = :password WHERE username = :username";
            $stmt = $connection->prepare($query);
            $stmt->bindParam(':password', $hashedPassword);
            $stmt->bindParam(':username', $username);
            try {
                $stmt->execute();
                $mailManager = new MailManager();
                $mailManager->sendMail($userMail, "Cambio de contraseña", $html);
                return true;
            } catch (PDOException $e) {
                echo "Error al actualizar la contraseña: " . $e->getMessage();
                return false;
            }
        }
    }
    function verifyPassword($username, $password)
    {
        $connection = $this->getConnection();
        $query = "SELECT password FROM users WHERE username = :username";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($user) {
            $pepper = "dondecaemosgente";
            $peperedPass = hash_hmac("sha256", $password, $pepper);
            return password_verify($peperedPass, $user['password']);
        }
        return false;
    }
    public function getEmailByUsername($username)
    {
        $connection = $this->getConnection();
        $query = "SELECT email FROM users WHERE username = :username";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':username', $username);
        $stmt->execute();
        return $stmt->fetchColumn();
    }
    public function getAllUsers()
    {
        $connection = $this->getConnection();
        $query = "SELECT * FROM users";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
    public function removeUserById($userId){
        $connection = $this->getConnection();
        $query = "DELETE FROM users WHERE ID = :userId";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':userId', $userId);
        try {
            $stmt->execute();
            return true;
        } catch (PDOException $e) {
            echo "Error al eliminar el usuario: " . $e->getMessage();
            return false;
        }
    }
    public function deactivateUserById($userId)
    {
        $connection = $this->getConnection();
        $query = "UPDATE users SET status = 'inactive' WHERE ID = :userId";
        $stmt = $connection->prepare($query);
        $stmt->bindParam(':userId', $userId);
        try {
            $stmt->execute();
            return true;
        } catch (PDOException $e) {
            echo "Error al desactivar el usuario: " . $e->getMessage();
            return false;
        }
    }
    public function getRecentActivity()
    {
        $connection = $this->getConnection();
        #Get all users added today
        $query = "SELECT * FROM users WHERE DATE(created_at) = CURDATE()";
        $stmt = $connection->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
