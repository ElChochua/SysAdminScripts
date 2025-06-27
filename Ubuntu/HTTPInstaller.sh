#!/bin/bash
#sudo apt update
source /media/sf_shared/Functions.sh
echo -e "Seleccione el servicio que desea instalar: \n 1.-Apache \n 2.-Nginx \n 3.-Tomcat"
read opcion
while (($opcion != 1 && $opcion != 2 && $opcion != 3)); do
    echo "Opcion invalida, porfavor seleccione una opcion valida"
    read -p "Seleccione el servicio que desea instalar: \n 1.-Apache \n 2.-Nginx \n 3.-Tomcat" opcion
done
case $opcion in
1)
#APACHE.
read -p "De que fuente quieres instalar Apache? \n1.-Web 2.-FTP: " installOption

versions=($(get_service_versions "apache2" $installOption))
echo "Versiones Disponibles: " 
print_array "${versions[@]}"
read -p "Elije una de las version." versionChoise
while (($versionChoise < 0 && $versionChoise > ${#versions[@]})); do
    echo "Opcion invalida, porfavor seleccione una opcion valida"
    print_array "${versions[@]}"
    read -p "Selecciona una opcion. " versionChoise
done
echo "Instalando Apache ${versions[$versionChoise]}..."
    install_service "apache" "${versions[$versionChoise]}"
    sudo ufw allow 'Apache'
sudo sed -i '/Listen/d' /etc/apache2/ports.conf
sudo systemctl restart apache2 2> /dev/null

read -p "Ingresa el nombre de tu servidor" folderName
while sudo ls /var/www/ | grep $folderName; do
echo "El nombre $folderName ya esta en uso, porfavor ingresa otro nombre"
read folderName
done
sudo mkdir -p /var/www/$folderName
sudo chown -R $USER:$USER /var/www
cp /var/www/html/index.html /var/www/$folderName/index.html
sudo find /var/www/$folderName/ -type d -exec chmod 755 {} \;
sudo find /var/www/$folderName/ -type f -exec chmod 744 {} \;
read -p "Indica el puerto que deseas utilizar" port 
while (sudo lsof -i :$port &>/dev/null) || (is_port_in_common_ports $port); do
    read -p "Ingresa un puerto: " port
done
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$folderName.conf
read -p "Instalar certificado SSL? 1.-Si 2.-No: " installSSL
if (($installSSL == 1)); then
certificate_key_path="/etc/ssl/private/apache-selfsigned.key"
certificate_path="/etc/ssl/certs/apache-selfsigned.crt"
sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048 \
-subj "/C=MX/ST=Sinaloa/L=Momochis/O=SexomatasFC/OU=Software/CN=chochua"
sudo truncate -s 0 /etc/apache2/sites-available/$folderName.conf
echo "<VirtualHost *:$port>" >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAdmin webmaster@localhost >> /etc/apache2/sites-available/$folderName.conf
echo    ServerName $folderName >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAlias www.$folderName >> /etc/apache2/sites-available/$folderName.conf
echo    DocumentRoot /var/www/$folderName   >> /etc/apache2/sites-available/$folderName.conf
echo    ErrorLog \${APACHE_LOG_DIR}/error.log    >> /etc/apache2/sites-available/$folderName.conf
echo    CustomLog \${APACHE_LOG_DIR}/access.log combined >> /etc/apache2/sites-available/$folderName.conf
echo    SSLEngine on >> /etc/apache2/sites-available/$folderName.conf
echo    SSLCertificateFile $certificate_path >> /etc/apache2/sites-available/$folderName.conf
echo    SSLCertificateKeyFile $certificate_key_path >> /etc/apache2/sites-available/$folderName.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$folderName.conf
sudo a2enmod ssl
else 
sudo truncate -s 0 /etc/apache2/sites-available/$folderName.conf
echo "<VirtualHost *:$port>" >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAdmin webmaster@localhost >> /etc/apache2/sites-available/$folderName.conf
echo    ServerName $folderName >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAlias www.$folderName >> /etc/apache2/sites-available/$folderName.conf
echo    DocumentRoot /var/www/$folderName   >> /etc/apache2/sites-available/$folderName.conf
echo    ErrorLog \${APACHE_LOG_DIR}/error.log    >> /etc/apache2/sites-available/$folderName.conf
echo    CustomLog \${APACHE_LOG_DIR}/access.log combined >> /etc/apache2/sites-available/$folderName.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$folderName.conf
fi

sudo echo "Listen $port" | sudo tee -a /etc/apache2/ports.conf > /dev/null
sudo a2ensite $folderName.conf
sudo a2dissite 000-default.conf
    sudo systemctl restart apache2
    sudo systemctl status apache2
    echo -e "Servidor corriendo en: el puerto $port\n"
    (ip -4 addr show | grep "inet" | awk '{print $2}' | grep -v "127.0.0.1")
;;
2)
#NGIN
read -p "De que fuente quieres instalar Nginx? \n1.-Web 2.-FTP: " installOption
versions=($(get_service_versions "nginx" $installOption))
echo "Versiones Disponibles: " 
print_array "${versions[@]}"
read -p "Elije una de las version." versionChoise
while (($versionChoise < 0 && $versionChoise > ${#versions[@]})); do
    echo "Opcion invalida, porfavor seleccione una opcion valida"
    print_array "${versions[@]}"
    read -p "Selecciona una opcion valida. " versionChoise
done
    #sudo apt-get purge nginx -y > /dev/null 2>&1
    #sudo add-apt-repository --remove -y ppa:ondrej/nginx > /dev/null 2>&2
    sudo apt-get autoremove -y > /dev/null 2>&1
    install_service "nginx" "${versions[$versionChoise]}"
sudo ufw allow 'Nginx HTTP'
    sudo sed -i '/listen/d' /etc/nginx/sites-available/default
    sudo sed -i '/listen [::]:/d' /etc/nginx/sites-available/default
sudo truncate -s 0 /etc/nginx/nginx.conf

    sudo systemctl stop nginx 2> /dev/null
    sudo systemctl restart nginx 2> /dev/null
    read -p "Ingresa el nombre de tu servidor" serverName
    while sudo ls /var/www/ | grep $serverName; do
        echo "El nombre $serverName ya esta en uso, porfavor ingresa otro nombre"
        read serverName
    done
    sudo mkdir -p /var/www/$serverName
    sudo chown -R $USER:$USER /var/www/$serverName
    sudo find /var/www/$serverName/ -type d -exec chmod 755 {} \;
    sudo find /var/www/$serverName/ -type f -exec chmod 744 {} \;
cp /var/www/html/index.nginx-debian.html /var/www/$serverName/index.html
read -p "Indica el puerto que deseas utilizar" port 
while (sudo lsof -i :$port &>/dev/null) || (is_port_in_common_ports $port); do
    read -p "Ingresa un puerto: " port
done
read -p "Instalar certificado SSL? 1.-Si 2.-No: " installSSL
if (($installSSL == 1)); then
certificate_key_path="/etc/ssl/private/nginx-selfsigned.key"
certificate_path="/etc/ssl/certs/nginx-selfsigned.crt"
sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048 \
-subj "/C=MX/ST=Sinaloa/L=Momochis/O=SexomatasFC/OU=Software/CN=chochua"
echo "    server { " >> /etc/nginx/sites-available/$serverName
echo "       listen [::]:$port ssl;" >> /etc/nginx/sites-available/$serverName
echo "       listen $port ssl;" >> /etc/nginx/sites-available/$serverName
echo "       ssl_certificate $certificate_path;" >> /etc/nginx/sites-available/$serverName
echo "       ssl_certificate_key $certificate_key_path;" >> /etc/nginx/sites-available/$serverName
echo "       root /var/www/$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/$serverName
echo "       server_name $serverName www.$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       location / {" >> /etc/nginx/sites-available/$serverName
echo "               try_files \$uri \$uri/ =404;" >> /etc/nginx/sites-available/$serverName
echo "       }">> /etc/nginx/sites-available/$serverName
echo "}">> /etc/nginx/sites-available/$serverName
else
echo "    server { " >> /etc/nginx/sites-available/$serverName
echo "       listen [::]:$port ssl;" >> /etc/nginx/sites-available/$serverName
echo "       root /var/www/$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/$serverName
echo "       server_name $serverName www.$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       location / {" >> /etc/nginx/sites-available/$serverName
echo "               try_files \$uri \$uri/ =404;" >> /etc/nginx/sites-available/$serverName
echo "       }">> /etc/nginx/sites-available/$serverName
echo "}">> /etc/nginx/sites-available/$serverName
fi
sudo rm -r /etc/nginx/sites-enabled/default
sudo rm -r /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/$serverName /etc/nginx/sites-enabled/

echo "user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;
events {
	worker_connections 768;
	# multi_accept on;
}
http {
	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;
	server_names_hash_bucket_size 64;
	# server_name_in_redirect off;
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;
	access_log /var/log/nginx/access.log;
	gzip on;
	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}" >> /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl status nginx
echo -e "Servidor corriendo en: el puerto $port\n"
(ip -4 addr show | grep "inet" | awk '{print $2}' | grep -v "127.0.0.1")
;;
3)
#TOMCAT
echo -e "Que version de Tomcat desea instalar? \n1.-Tomcat 10 \n2.-Tomcat 9"
read tomcatOption
while (($tomcatOption != 1 && $tomcatOption != 2)); do
    echo "Opcion invalida, porfavor seleccione una opcion valida"
    read -p "Que version de Tomcat desea instalar? \n1.-Tomcat 10 \n2.-Tomcat 9" tomcatOption
done
read -p "Quieres instalar desde el server FTP o Web? \n1.-Web 2.-FTP: " installOption
case $tomcatOption in
1)
    tomcat_version=10
    install_tomcat "$tomcat_version" $installOption
    ;;
2)
    tomcat_version=9
    install_tomcat "$tomcat_version" $installOption
    ;;
esac

(ip -4 addr show | grep "inet" | awk '{print $2}' | grep -v "127.0.0.1")
;;
esac