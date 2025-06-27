echo -e "Certificados Disponibles\n1.-Apache\n2.-Nginx\n3.-Tomcat"
read -p "Que certificado quieres genrara ?" certOption
case $certOption in
1)
certificate_key_path="/etc/ssl/private/apache-selfsigned.key"
certificate_path="/etc/ssl/certs/apache-selfsigned.crt"
sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048
sudo a2enmod ssl
#Necesary Lines to enable SSL Configuration in Apache.
echo    SSLEngine on >> /etc/apache2/sites-available/$folderName.conf
echo    SSLCertificateFile $certificate_path >> /etc/apache2/sites-available/$folderName.conf
echo    SSLCertificateKeyFile $certificate_key_path >> /etc/apache2/sites-available/$folderName.conf

;;
2)
certificate_key_path="/etc/ssl/private/nginx-selfsigned.key"
certificate_path="/etc/ssl/certs/nginx-selfsigned.crt"
sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048
#Necesary Lines to enable SSL Configuration in Nginx.
echo "       listen [::]:$port ssl;" >> /etc/nginx/sites-available/$serverName
echo "       listen $port ssl;" >> /etc/nginx/sites-available/$serverName
echo "       ssl_certificate $certificate_path;" >> /etc/nginx/sites-available/$serverName
echo "       ssl_certificate_key $certificate_key_path;" >> /etc/nginx/sites-available/$serverName
;;
3)
certificate_key_path="/etc/ssl/private/tomcat-selfsigned.key"
certificate_path="/etc/ssl/certs/tomcat-selfsigned.crt"
sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048

certificate_key_tomcat="/etc/ssl/certs/http-selfsigned.cert"
keytool -genkey -alias tomcat -keyalg RSA -keystore $certificate_key_tomcat
read -p "Ingresa la contraseña para el certificado" certificate_password
xmlstarlet ed -L \
  -s "/Server/Service" -t elem -n "Connector" \
  -i "/Server/Service/Connector[last()]" -t attr -n "port" -v "8443" \
  -i "/Server/Service/Connector[last()]" -t attr -n "protocol" -v "org.apache.coyote.http11.Http11NioProtocol" \
  -i "/Server/Service/Connector[last()]" -t attr -n "maxThreads" -v "150" \
  -i "/Server/Service/Connector[last()]" -t attr -n "SSLEnabled" -v "true" \
  -i "/Server/Service/Connector[last()]" -t attr -n "maxParameterCount" -v "1000" \
  -s "/Server/Service/Connector[last()]" -t elem -n "UpgradeProtocol" \
  -i "/Server/Service/Connector[last()]/UpgradeProtocol" -t attr -n "className" -v "org.apache.coyote.http2.Http2Protocol" \
  -s "/Server/Service/Connector[last()]" -t elem -n "SSLHostConfig" \
  -s "/Server/Service/Connector[last()]/SSLHostConfig" -t elem -n "Certificate" \
  -i "/Server/Service/Connector[last()]/SSLHostConfig/Certificate" -t attr -n "certificateKeystoreFile" -v "$certificate_key_tomcat" \
  -i "/Server/Service/Connector[last()]/SSLHostConfig/Certificate" -t attr -n "certificateKeystorePassword" -v "$certificate_password" \
  -i "/Server/Service/Connector[last()]/SSLHostConfig/Certificate" -t attr -n "type" -v "RSA" \
  /opt/tomcat/conf/server.xml
sed -i '/<response-character-encoding>UTF-8<\/response-character-encoding>/a\
    <security-constraint> \
        <web-resource-collection>\
            <web-resource-name>Entire Application</web-resource-name>\
            <url-pattern>/*</url-pattern>\
        </web-resource-collection>\
        <user-data-constraint>\
            <transport-guarantee>CONFIDENTIAL</transport-guarantee>\
        </user-data-constraint>\
    </security-constraint>' /opt/tomcat/conf/web.xml
;;