#!/bin/bash
echo "Debes haber configurado el servidor DNS antes y debe coincidir con tu hostname: "
hostname
read -p "Ingresa el dominio de tu servidor: " domain
sudo hostnamectl set-hostname $domain
sudo hostnamectl set-hostname --static $domain
echo "El nombre del dominio ha sido cambiado a $domain"
sudo apt-get install -y postfix
sudo cat /etc/mailname
sleep 3
sudo apt-get install -y dovecot-pop3d
read -p "Ingresa la direccion raiz de la red de tu server ej.192.168.1.0: " root_ip
sudo sed -i '/mynetworks/d' /etc/postfix/main.cf
sudo echo "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $root_ip/24" | sudo tee -a /etc/postfix/main.cf > /dev/null
echo "mail_home = Maildir/" >> /etc/postfix/main.cf
echo "mail_command = " >> /etc/postfix/main.cf
sudo systemctl restart postfix
sudo sed -i '/#disable_plaintext_auth = yes/d' /etc/dovecot/conf.d/10-auth.conf
sudo echo "disable_plaintext_auth = no" | sudo tee -a /etc/dovecot/conf.d/10-auth.conf > /dev/null
sudo sed -i '/#   mail_location = maildir:~\/Maildir/d' /etc/dovecot/conf.d/10-mail.conf
sudo echo "mail_location = maildir:~/Maildir" | sudo tee -a /etc/dovecot/conf.d/10-mail.conf > /dev/null
sudo sed -i '/mail_location = mbox:/d' /etc/dovecot/conf.d/10-mail.conf
sudo echo "#mail_location = mbox:~/mail:INBOX=/var/mail/%u" | sudo tee -a /etc/dovecot/conf.d/10-mail.conf > /dev/null
sudo systemctl restart dovecot
zones=$(ls /etc/bind/zones/)
zones_array=($zones)
for i in "${!zones_array[@]}"; do
    echo "$i.- ${zones_array[$i]}"
done
read -p "Selecciona una Zona " zone
selected_zone=${zones_array[$zone]}
read -p "Ingresa la direccion IP de tu servidor: " HTTP_IP
echo "chochua.local IN  MX  10  correo.chochua.local." >> /etc/bind/zones/$selected_zone 
echo "pop3   IN  CNAME   $HTTP_IP" >> /etc/bind/zones/$selected_zone
echo "smtp   IN  CNAME   $HTTP_IP" >> /etc/bind/zones/$selected_zone
sudo apt-get install -y mysql-server
sudo apt-get install -y dovecot-imapd
sudo apt-get install -y roundcube
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/round.conf
sudo sed -i '/DocumentRoot/d' /etc/apache2/sites-available/round.conf
sudo echo "DocumentRoot /var/lib/roundcube" | sudo tee -a /etc/apache2/sites-available/round.conf > /dev/null
sudo a2ensite round.conf