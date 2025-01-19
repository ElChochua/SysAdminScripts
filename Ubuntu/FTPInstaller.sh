#!/bin/bash
sudo apt install vsftpd
clear
sudo mkdir /home/FTP
sudo chmod -R 755 /home/FTP
read -p "Ingresa el nombre de la carpeta principal: " mainFolder
sudo mkdir /home/FTP/$mainFolder
sudo chmod -R 777 /home/FTP/$mainFolder

sudo truncate -s 0 /etc/vsftpd.conf
echo "listen=NO" >> /etc/vsftpd.conf
echo "listen_ipv6=YES" >> /etc/vsftpd.conf
echo "anonymous_enable=YES" >> /etc/vsftpd.conf
echo "anon_root=/home/FTP" >> /etc/vsftpd.conf
echo "anon_upload_enable=NO" >> /etc/vsftpd.conf
echo "write_enable=YES" >> /etc/vsftpd.conf
echo "local_enable=YES" >> /etc/vsftpd.conf
echo "chroot_local_user=YES" >> /etc/vsftpd.conf
echo "allow_writeable_chroot=YES" >> /etc/vsftpd.conf
echo "dirmessage_enable=YES" >> /etc/vsftpd.conf
echo "use_localtime=YES" >> /etc/vsftpd.conf
echo "xferlog_enable=YES" >> /etc/vsftpd.conf
echo "connect_from_port_20=YES" >> /etc/vsftpd.conf
echo "secure_chroot_dir=/var/run/vsftpd/empty" >> /etc/vsftpd.conf
echo "pam_service_name=vsftpd" >> /etc/vsftpd.conf
echo "rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem" >> /etc/vsftpd.conf
echo "rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key" >> /etc/vsftpd.conf
echo "ssl_enable=NO" >> /etc/vsftpd.conf


read -p "Ingresa el nombre para el grupo A " groupA_name
sudo groupadd $groupA_name
sudo mkdir /home/$groupA_name

read -p "Ingresa el nombre para el grupo B " groupB_name
sudo groupadd $groupB_name
sudo mkdir /home/$groupB_name
sudo chmod 770 /home/$groupA_name
sudo chmod 770 /home/$groupB_name
sudo chgrp  $groupA_name /home/$groupA_name
sudo chgrp  $groupB_name /home/$groupB_name
sudo chown :$groupA_name /home/$groupA_name
sudo chown :$groupB_name /home/$groupB_name

read -p "Numero de usuarios a agregar: " user_count
for ((i=1; i<=$user_count; i++))
do
    read -p "$i. Ingresa el nombre del usuario: " user_name
    read -p "$i. Ingresa la contraseña: " -s user_password
    sudo useradd -m $user_name
    echo "$user_name:$user_password" | sudo chpasswd
    read -p "$i. Ingresa el grupo al que pertenece: " user_group
    sudo usermod -a -G $user_group $user_name

    sudo mkdir /home/$user_name/General
    sudo mkdir /home/$user_name/Personal
    sudo mkdir /home/$user_name/$user_group
    sudo chmod 775 /home/$user_name/General
    sudo chmod 700 /home/$user_name/Personal
    sudo chmod 775 /home/$user_name/$user_group
    sudo chown $user_name:$user_name /home/$user_name/General
    sudo chown $user_name:$user_name /home/$user_name/Personal
    sudo chown $user_name:$user_group /home/$user_name/$user_group
    sudo mount --bind /home/FTP/$mainFolder /home/$user_name/General
    sudo mount --bind /home/$user_group /home/$user_name/$user_group
done

sudo systemctl restart vsftpd
sudo systemctl status vsftpd