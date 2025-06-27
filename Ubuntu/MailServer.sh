#!/bin/bash
hostname
read -p "Ingresa el dominio de tu servidor: " domain
sudo hostnamectl set-hostname --static $domain
echo "El nombre del dominio ha sido cambiado a $domain"
#sudo apt-get update -y
#sudo apt-get upgrade -y
sudo apt-get install  postfix
sudo apt-get install dovecot-imapd dovecot-pop3d -y
sudo apt-get install apache2 -y
sudo apt-get install mysql-server -y
sudo apt-get install roundcube -y

cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/round.conf
sudo sed -i "s/#ServerName www.example.com/ServerName $domain /"  /etc/apache2/sites-available/round.conf
sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/lib\/roundcube/' /etc/apache2/sites-available/round.conf
echo "<Directory /var/lib/roundcube>
    Require all granted
</Directory>" | sudo tee -a /etc/apache2/sites-available/round.conf
sudo a2ensite round.conf
sudo a2dissite 000-default.conf
sudo systemctl reload apache2
sudo systemctl restart apache2

sudo sed -i "/\$config\['imap_host'\] =/d" /etc/roundcube/config.inc.php
sudo echo "\$config['imap_host'] = [\"$domain:143\"];" | sudo tee -a /etc/roundcube/config.inc.php > /dev/null
sudo sed -i "/\$config\['smtp_host'\] =/d" /etc/roundcube/config.inc.php
sudo echo "\$config['smtp_host'] = '$domain:25';" | sudo tee -a /etc/roundcube/config.inc.php > /dev/null
sudo sed -i "/\$config\['smtp_user'\] =/d" /etc/roundcube/config.inc.php
sudo echo "\$config['smtp_user'] = '';" | sudo tee -a /etc/roundcube/config.inc.php > /dev/null
sudo sed -i "/\$config\['smtp_pass'\] =/d" /etc/roundcube/config.inc.php
sudo echo "\$config['smtp_pass'] = '';" | sudo tee -a /etc/roundcube/config.inc.php > /dev/null

echo "\$config['log_driver'] = 'syslog';" | sudo tee -a /etc/roundcube/config.inc.php
echo "\$config['syslog_facility'] = LOG_MAIL;" | sudo tee -a /etc/roundcube/config.inc.php
read -p "Ingresa la direccion raiz de la red de tu server ej.192.168.1.0: " root_ip
sudo sed -i '/mynetworks/d' /etc/postfix/main.cf
sudo echo "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $root_ip/24" | sudo tee -a /etc/postfix/main.cf > /dev/null
echo "protocols = pop3 imap" | sudo tee -a /etc/dovecot/dovecot.conf > /dev/null
echo "disable_plaintext_auth = no" | sudo tee -a /etc/dovecot/conf.d/10-auth.conf > /dev/null
sudo sed -i '/auth_mechanisms/d' /etc/dovecot/conf.d/10-auth.conf
echo "auth_mechanisms = plain login" | sudo tee -a /etc/dovecot/conf.d/10-auth.conf > /dev/null
echo "auth_mechanisms = plain" | sudo tee -a /etc/dovecot/conf.d/10-auth.conf > /dev/null
echo "auth_username_format = %n" | sudo tee -a /etc/dovecot/conf.d/10-auth.conf > /dev/null

sudo tee /etc/bind/db.$domain > /dev/null <<EOF
\$TTL 604800
@   IN  SOA     $domain. root.$domain. (
                1           ; Serial
                604800      ; Refresh
                86400       ; Retry
                2419200     ; Expire
                604800 )    ; Negative Cache TTL

; Servidores de nombres
@   IN  NS      ns.$domain.
ns  IN  A       $ip_server

; Registros A
@    IN  A      $ip_server
mail IN  A      $ip_server
webmail IN A    $ip_server

; Registro MX
@   IN  MX 10   mail.$domain.

; Servicios de correo
imap IN  A      $ip_server
pop3 IN  A      $ip_server
smtp IN  A      $ip_server
EOF

# Configurar named.conf.local
#sudo tee -a /etc/bind/named.conf.local > /dev/null <<EOF
#zone "$domain" {
#    type master;
#    file "/etc/bind/db.$domain";
#};
#EOF

sudo systemctl restart bind9
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl restart apache2

echo "Servidor configurado."