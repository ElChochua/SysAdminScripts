<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
require_once __DIR__ . '/../phpmailer/src/PHPMailer.php';
require_once __DIR__ . '/../phpmailer/src/Exception.php';
require_once __DIR__ . '/../phpmailer/src/SMTP.php';
    class MailManager{
        public $mail;
        public function __construct(){
         try{
            $this->mail = new PHPMailer();
            $this->mail->isSMTP();
            $this->mail->Host = 'smtp.gmail.com';
            $this->mail->SMTPAuth = true;
            $this->mail->Username = 'reprobadosworkgroup@gmail.com';
            $this->mail->Password = 'fqbudzzdhyrslfyk';
            $this->mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
            $this->mail->isHTML(true);
            $this->mail->Port = 587;
         }catch(Exception $e){
            echo "Error al configurar el servidor SMTP: {$this->mail->ErrorInfo} \n Exception: {$e->getMessage()}";
         }
        }
        public function sendMail($to, $subject, $body){
            try{
            $this->mail->setFrom('reprobadosworkgroup@gmail.com');
            $this->mail->addAddress($to);
            $this->mail->Subject = $subject;
            $this->mail->Body = $body;
            $this->mail->send();
            }catch(Exception $e){
                echo "Error al enviar el correo: {$this->mail->ErrorInfo}";
            }
        }
    }
?>