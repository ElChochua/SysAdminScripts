<?php
    require_once __DIR__ . '\..\core\auth.php';
    $auth = new Authenticator();
    $auth->logout();
?>