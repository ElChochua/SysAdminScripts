#!/bin/bash
echo "Debes haber configurado el servidor DNS antes y debe coincidir con tu hostname: "
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

zones=$(ls /etc/bind/zones/)
zones_array=($zones)
for i in "${!zones_array[@]}"; do
    echo "$i.- ${zones_array[$i]}"
done

read -p "Selecciona una Zona " zone
selected_zone=${zones_array[$zone]}
read -p "Ingresa la direccion IP de tu servidor: " HTTP_IP
sudo sed -i "/pop3/d" /etc/bind/zones/$selected_zone
sudo sed -i "/smtp/d" /etc/bind/zones/$selected_zone
sudo sed -i "/correo/d" /etc/bind/zones/$selected_zone
echo "$domain. IN MX 10 $domain." >> /etc/bind/zones/$selected_zone
echo "pop3   IN  CNAME   server" >> /etc/bind/zones/$selected_zone
echo "smtp   IN  CNAME   server" >> /etc/bind/zones/$selected_zone
sudo systemctl reload postfix
sudo systemctl restart postfix
sudo systemctl restart dovecot
sudo systemctl restart bind9
