<?php
    require_once __DIR__ . '\DatabaseManager.php';
    class Authenticator{
        private $connection;
        function __construct(){
            $manager = new DatabaseManager();
            $this->connection = $manager->getConnection();
        }
        public function login($username, $password){
            $query = "SELECT * FROM users WHERE username = :username";
            $stmt = $this->connection->prepare($query);
            $stmt->bindParam(':username', $username);
            $stmt->execute();
            $user = $stmt->fetch(PDO::FETCH_ASSOC);
            if($user){
                $pepper = "dondecaemosgente";
                $peperedPass = hash_hmac("sha256", $password, $pepper);
                if(password_verify($peperedPass, $user['password'])){
                    return true;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
        function logout(){
            session_start();
            session_unset();
            session_destroy();
            header("Location: /index.php");
            exit();
        }
    }
?>