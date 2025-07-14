<?php
    class ServerManager{
        private $adminUser = "Administrator";
        private $sshHost = "localhost";
        public function testeillo(){
            return exec("powershell.exe Get-ADDomain");
        }
    }

?>
