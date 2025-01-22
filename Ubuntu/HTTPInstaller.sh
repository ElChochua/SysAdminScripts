#!/bin/bash
#sudo apt update

echo -e "Seleccione el servicio que desea instalar: \n 1.-Apache \n 2.-Nginx \n 3.-Tomcat"
read opcion
case $opcion in
1)
#APACHE.
read -p "Porfavor seleccione la version de apache que desea instalar: \n 1.-Apache LTS \n 2.-Apache Dev-Build" versionChoise
if (($versionChoise == 1)); then
    sudo apt-get purge apache2 -y > /dev/null 2>&1
    sudo add-apt-repository --remove -y ppa:ondrej/apache2 > /dev/null 2>&2
    sudo apt-get autoremove -y > /dev/null 2>&1
    sudo apt install -y apache2
    sudo ufw allow 'Apache'
else
    sudo add-apt-repository -y ppa:ondrej/apache2 > /dev/null 2>&1
    sudo update > /dev/null 2>&1
    sudo apt install -y apache2 
fi
read -p "Ingresa el nombre de tu servidor" folderName
while sudo ls /var/www/ | grep $folderName; do
echo "El nombre $folderName ya esta en uso, porfavor ingresa otro nombre"
read folderName
done
sudo mkdir -p /var/www/$folderName
sudo chown -R $USER:$USER /var/www
cp /media/sf_shared/index.html /var/www/$folderName/index.html
sudo find /var/www/$folderName/ -type d -exec chmod 755 {} \;
sudo find /var/www/$folderName/ -type f -exec chmod 744 {} \;
read -p "Indica el puerto que deseas utilizar" port 
while sudo lsof -i :$port; do
    read -p "El puerto $port ya esta en uso, porfavor ingresa otro puerto" port
done
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$folderName.conf
sudo truncate -s 0 /etc/apache2/sites-available/$folderName.conf
echo "<VirtualHost *:$port>" >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAdmin webmaster@localhost >> /etc/apache2/sites-available/$folderName.conf
echo    ServerName $folderName >> /etc/apache2/sites-available/$folderName.conf
echo    ServerAlias www.$folderName >> /etc/apache2/sites-available/$folderName.conf
echo    DocumentRoot /var/www/$folderName   >> /etc/apache2/sites-available/$folderName.conf
echo    ErrorLog ${APACHE_LOG_DIR}/error.log    >> /etc/apache2/sites-available/$folderName.conf
echo    CustomLog ${APACHE_LOG_DIR}/access.log combined >> /etc/apache2/sites-available/$folderName.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$folderName.conf
sudo sed -i '/Listen/d' /etc/apache2/ports.conf
sudo echo "Listen $port" | sudo tee -a /etc/apache2/ports.conf > /dev/null
sudo a2ensite $folderName.conf
sudo a2dissite 000-default.conf
echo -e "EN CASO DE TENER CONFIGURADO EL SERVIDOR DNS \n Quieres agregar el servidor a la lista de DNS ? 1.-Si \n 2.-No"
read dnsChoise
echo $dnsChoise
if (($dnsChoise == 1)); 
    then
    zones=$(ls /etc/bind/zones/)
    zones_array=($zones)
    for i in "${!zones_array[@]}"; do
        echo "$i.- ${zones_array[$i]}"
    done
    read -p "Selecciona una Zona " zone
    selected_zone=${zones_array[$zone]}
    read -p "Ingresa la direccion IP de tu servidor HTTP: " HTTP_IP
    echo "$folderName.com   IN  A   $HTTP_IP" >> /etc/bind/zones/$selected_zone
    systemctl restart bind9
    echo "Agregando el servidor a la lista de DNS"
    sleep 1
    sudo systemctl restart apache2 
    sudo systemctl status apache2
else 
    sudo systemctl restart apache2
    sudo systemctl status apache2
fi
;;
2)
#NGINX
read -p "Porfavor seleccione la version de nginx que desea instalar: \n 1.-Nginx LTS \n 2.-Nginx Dev-Build" versionChoise
if (($versionChoise == 1)); then
    sudo apt-get purge nginx -y > /dev/null 2>&1
    sudo add-apt-repository --remove -y ppa:ondrej/nginx > /dev/null 2>&2
    sudo apt-get autoremove -y > /dev/null 2>&1
    sudo apt install nginx -y
else
    sudo apt install nginx-dev
fi
sudo ufw allow 'Nginx HTTP'
    read -p "Ingresa el nombre de tu servidor" serverName
    while sudo ls /var/www/ | grep $serverName; do
        echo "El nombre $serverName ya esta en uso, porfavor ingresa otro nombre"
        read serverName
    done
    sudo mkdir -p /var/www/$serverName
    sudo chown -R $USER:$USER /var/www/$serverName
    cp /media/sf_shared/index.html /var/www/$serverName/index.html
    sudo find /var/www/$serverName/ -type d -exec chmod 755 {} \;
    sudo find /var/www/$serverName/ -type f -exec chmod 744 {} \;
    read -p "Indica el puerto que deseas utilizar" port
    while sudo lsof -i :$port; do
        read -p "El puerto $port ya esta en uso, porfavor ingresa otro puerto" port
    done
echo "    server { " >> /etc/nginx/sites-available/$serverName
echo "       listen $port;" >> /etc/nginx/sites-available/$serverName
echo "       listen [::]:$port;" >> /etc/nginx/sites-available/$serverName
echo "       root /var/www/$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       index index.html index.htm index.nginx-debian.html;" >> /etc/nginx/sites-available/$serverName
echo "       server_name $serverName www.$serverName;" >> /etc/nginx/sites-available/$serverName
echo "       location / {" >> /etc/nginx/sites-available/$serverName
echo "               try_files \$uri \$uri/ =404;" >> /etc/nginx/sites-available/$serverName
echo "       }">> /etc/nginx/sites-available/$serverName
echo "}">> /etc/nginx/sites-available/$serverName
sudo rm -r /etc/nginx/sites-enabled/default
sudo rm -r /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/$serverName /etc/nginx/sites-enabled/
sudo truncate -s 0 /etc/nginx/nginx.conf
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
read -p "Desea agregar el servidor a la lista de DNS? 1.-Si 2.-No" dnsChoise
if (($dnsChoise == 1)); then
    zones=$(ls /etc/bind/zones/)
    zones_array=($zones)
    for i in "${!zones_array[@]}"; do
        echo "$i.- ${zones_array[$i]}"
    done
    read -p "Selecciona una Zona " zone
    selected_zone=${zones_array[$zone]}
    read -p "Ingresa la direccion IP de tu servidor HTTP: " HTTP_IP
    echo "$serverName.com   IN  A   $HTTP_IP" >> /etc/bind/zones/$selected_zone
    systemctl restart bind9
    echo "Agregando el servidor a la lista de DNS"
    sleep 1
    sudo systemctl restart nginx
    sudo systemctl status nginx
else
    sudo systemctl restart nginx
    sudo systemctl status nginx
fi
;;
3)
#TOMCAT
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat
#sudo apt install -y default-jdk
read -p "Ingrese el nombre de su servidor" serverName
echo -e "Que version de Tomcat desea instalar? \n1.-Tomcat 10 \n2.-Tomcat 9"
read tomcatOption
if(($tomcatOption == 1)); then
    wget -P /tmp https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz
    sudo tar xzvf /tmp/apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1
else
    wget -P /tmp https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz
    sudo tar xzvf /tmp/apache-tomcat-9*tar.gz -C /opt/tomcat --strip-components=1
fi
    sudo chown -R tomcat:tomcat /opt/tomcat/
    sudo chmod -R u+x /opt/tomcat/bin
    read -p "Ingresa el nombre de usuario para el administrador: " userName
    read -p "Ingresa la contraseña para el administrador: " userPassword
    sudo truncate -s 0 /opt/tomcat/conf/tomcat-users.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<tomcat-users xmlns=\"http://tomcat.apache.org/xml\"
              xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
              xsi:schemaLocation=\"http://tomcat.apache.org/xml tomcat-users.xsd\"
              version=\"1.0\">
<!--
  <user username=\"admin\" password=\"<must-be-changed>\" roles=\"manager-gui\"/>
  <user username=\"robot\" password=\"<must-be-changed>\" roles=\"manager-script\"/>
-->

  <role rolename=\"manager-gui\"/>
  <user username=\"manager\" password=\"manager\" roles=\"manager-gui\"/>
  <role rolename=\"admin-gui\"/>
  <user username=\"$username\" password=\"$userPassword\" roles=\"admin-gui\"/>
</tomcat-users>
" >> /opt/tomcat/conf/tomcat-users.xml

jdk_route=$(update-java-alternatives -l | grep openjdk | awk '{print $3}')
sudo truncate -s 0 /opt/tomcat/webapps/manager/META-INF/context.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "<Context antiResourceLocking=\"false\" privileged=\"true\">" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "    <CookieProcessor className=\"org.apache.tomcat.util.http.Rfc6265CookieProcessor\"" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "                    sameSiteCookies=\"strict\" />" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "    <Manager sessionAttributeValueClassNameFilter=\"java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\\$LruCache(?:\\\$1)?|java\\.util\\.(?:Linked)?HashMap\" />" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "</Context>" >> /opt/tomcat/webapps/manager/META-INF/context.xml


sudo truncate -s 0 /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "<Context antiResourceLocking=\"false\" privileged=\"true\">" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "    <CookieProcessor className=\"org.apache.tomcat.util.http.Rfc6265CookieProcessor\" sameSiteCookies=\"strict\" />" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "    <Manager sessionAttributeValueClassNameFilter=\"java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\\$LruCache(?:\\\$1)?|java\\.util\\.(?:Linked)?HashMap\" />" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "</Context>" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml

sudo truncate -s 0 /etc/systemd/system/tomcat.service
echo "[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=\"$jdk_route\"
Environment=\"JAVA_OPTS=-Djava.security.egd=file:///dev/urandom\"
Environment=\"CATALINA_BASE=/opt/tomcat\"
Environment=\"CATALINA_HOME=/opt/tomcat\"
Environment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tomcat.service
read -p "Desea agregar el servidor a la lista de DNS? 1.-Si 2.-No" dnsChoise
if (($dnsChoise == 1)); then
    zones=$(ls /etc/bind/zones/)
    zones_array=($zones)
    for i in "${!zones_array[@]}"; do
        echo "$i.- ${zones_array[$i]}"
    done
    read -p "Selecciona una Zona " zone
    selected_zone=${zones_array[$zone]}
    read -p "Ingresa la direccion IP de tu servidor HTTP: " HTTP_IP
    echo "$serverName.com   IN  A   $HTTP_IP" >> /etc/bind/zones/$selected_zone
    systemctl restart bind9
    echo "Agregando el servidor a la lista de DNS"
    sleep 1
    sudo systemctl restart nginx
    sudo systemctl status nginx
else
    sudo systemctl restart nginx
    sudo systemctl status nginx
fi
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo ufw allow 8080
sudo systemctl status tomcat
;;
esac