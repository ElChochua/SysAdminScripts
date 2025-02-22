sudo hostnamectl set-hostname reprobados.com
sudo apt-get update -y


sudo apt-get install postfix
sudo apt-get install apache2 -y


cat /etc/mailname
#en caso de que el nombre no coincida con nuestro dominio
#nano /etc/mailname
#sudo systemctl restart postfix

#an;adir usuario de prueba
clear
sudo adduser daniel
clear
sudo adduser daniel

sudo apt-get install bsd-mailx -y
sudo apt-get install dovecot-pop3d -y

clear
ifconfig

echo 'Ingrese la familia de la subred (ej. 192.168.1.0):'
read SubnetIP

sudo sed -i "s/^mynetworks = .*/mynetworks = 127.0.0.0\/8 [::ffff:127.0.0.0]\/104 [::1]\/128 ${SubnetIP}\/24/" /etc/postfix/main.cf
echo "home_mailbox = Maildir/" | sudo tee -a /etc/postfix/main.cf
echo "mailbox_command =" | sudo tee -a /etc/postfix/main.cf

sudo systemctl reload postfix
sudo systemctl restart postfix


sudo sed -i 's/^#disable_plaintext_auth = yes/disable_plaintext_auth = no/' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^#   mail_location = maildir:\/Maildir/    mail_location = maildir:\/Maildir/' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i 's/^mail_location = mbox:\/mail:INBOX=\/var\/mail\/%u/#mail_location = mbox:\/mail:INBOX=\/var\/mail\/%u/' /etc/dovecot/conf.d/10-mail.conf



sudo systemctl restart dovecot
#sudo systemctl status dovecot

#modificar db.reprodados.com
echo "reprobados.com   IN  MX  10  correo.reprobados.com." | sudo tee -a /etc/bind/zonas/db.reprobados.com
echo "pop3 IN  CNAME   servidor" | sudo tee -a /etc/bind/zonas/db.reprobados.com
echo "smtp IN  CNAME   servidor" | sudo tee -a /etc/bind/zonas/db.reprobados.com
sudo systemctl restart bind9


sudo apt-get install mysql-server -y
sudo apt-get install dovecot-imapd
clear
sudo apt-get install roundcube -y
echo 'pausa'
read a


clear
cd /etc/apache2/sites-available/
sudo cp 000-default.conf round.conf
#sudo sed -i 's/^#ServerName www.example.com/ServerName correo.reprobados.com/' /etc/apache2/sites-available/round.conf
sudo sed -i 's/#ServerName www.example.com/ServerName correo.reprobados.com/' /etc/apache2/sites-available/round.conf
sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/lib\/roundcube/' /etc/apache2/sites-available/round.conf


sudo systemctl restart apache2

cd /etc/apache2/sites-enabled
sudo a2ensite round.conf

sudo systemctl reload apache2

#agregar correo a db.reprobados.com
echo "correo  IN   CNAME   servidor" | sudo tee -a /etc/bind/zonas/db.reprobados.com
sudo systemctl restart bind9

clear
sudo sed -i "s/\$config\['default_host'\] = ''/\$config\['default_host'\] = 'reprobados.com'/g" /etc/roundcube/config.inc.php
sudo sed -i "s/\$config\['smtp_server'\] = 'localhost'/\$config\['smtp_server'\] = 'reprobados.com'/g" /etc/roundcube/config.inc.php
#sudo sed -i "s/\$config\['smtp_port'\] = '587';/\$config\['smtp_port'\] = '25';/g" /etc/roundcube/config.inc.php
sudo sed -i "s/\$config\['smtp_port'\] = 587;/\$config['smtp_port'] = 25;/" /etc/roundcube/config.inc.php
sudo sed -i "s/\$config\['smtp_user'\] = '%u'/\$config\['smtp_user'\] = ''/g" /etc/roundcube/config.inc.php

sudo systemctl restart apache2

echo "<Directory /var/lib/roundcube>
    Require all granted
</Directory>" | sudo tee -a /etc/apache2/sites-available/round.conf

sudo systemctl restart apache2