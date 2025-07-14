#!/bin/bash

ftp_route="ftp://localhost/General/Resources"

ip_reverse_zone() {
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[3]}.${byte[2]}.${byte[1]}.${byte[0]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}

remove_last_byte_and_rev() {
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[2]}.${byte[1]}.${byte[0]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}

get_last_byte() {
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[3]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}

validate_userName() {
    local user_name=$1
    if [[ "$user_name" =~ ^[a-z0-9_-]{3,15}$ ]]; then
        return 0
    else
        echo "Error: Nombre de usuario no válido"
        return 1
    fi
}

user_exists() {
    local user_name=$1
    if id -u "$user_name" >/dev/null 2>&1; then
        return 0
    else
        echo "Error: El usuario no existe"
        return 1
    fi
}

group_exists() {
    local group_name=$1
    if getent group "$group_name" >/dev/null 2>&1; then
        return 0
    else
        echo "Error: El grupo no existe"
        return 1
    fi
}

port_is_valid() {
    local port=$1
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 -a "$port" -le 65535 ]; then
        return 0
    else
        echo "Error: Puerto no válido"
        return 1
    fi
}

is_port_in_common_ports() {
    local port=$1
    case $port in
        20|21|22|23|25|53|110|143|443|465|587|993|995|3306|5432|8080|8443)
            echo "Error: Puerto reservado"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

user_in_group() {
    local user_name=$1
    local group_name=$2
    if groups "$user_name" | grep -w "$group_name" &>/dev/null; then
        return 0
    else
        echo "Error: El usuario no está en el grupo"
        return 1
    fi
}

user_in_reprobados_o_recursados() {
    local usuario="$1"
    grupos_usuario=$(id -Gn "$usuario" 2>/dev/null)
    for grupo in $grupos_usuario; do
        if [[ "$grupo" == "reprobados" || "$grupo" == "recursados" ]]; then
            return 0
        fi
    done
    return 1
}

install_packages() {
    local service="$1"
    nginx_d=(
        "libc6"
        "libcrypt1"
        "libpcre2-8-0"
        "libssl3"
        "zlib1g"
        "iproute2"
        "nginx-common"
    )
    util_packages=(
        "xmlstarlet"
        "curl"
        "wget"
        "unzip"
        "zip"
        "git"
        "net-tools"
        "ufw"
        "libapache2-mod-jk"
        "authbind"
    )
    for pack in "${util_packages[@]}"; do
        if ! package_installed "$pack"; then
            sudo apt-get install -y "$pack" >>/dev/null
        fi
    done
    if [ "$service" == "apache" ]; then
        for package in libapr1-dev libaprutil1-dev libpcre3 libpcre3-dev; do
            if ! package_installed "$package"; then
                sudo apt-get install -y "$package" >>/dev/null
            fi
        done
    elif [ "$service" == "nginx" ]; then
        for package in "${nginx_d[@]}"; do
            if ! package_installed "$package"; then
                sudo apt-get install -y "$package" >>/dev/null
            fi
        done
    elif [ "$service" == "tomcat" ]; then
        for package in default-jdk; do
            if ! package_installed "$package"; then
                sudo apt-get install -y "$package" >>/dev/null
            fi
        done
    fi
    apt --fix-broken install >>/dev/null
}

install_service() {
    local service="$1"
    local version="$2"
    local download_source="$3"

    if ((download_source == 1)); then
        if [ "$service" == "apache" ]; then
        install_packages "$service"
        sudo apt-get install --allow-downgrades -y \
            apache2="$version" \
            apache2-bin="$version" \
            apache2-data="$version" \
            apache2-utils="$version"
       elif [ "$service" == "nginx" ]; then
        sudo apt remove --purge nginx nginx-common nginx-core -y 2>/dev/null
        sudo apt autoremove -y 2>/dev/null
        install_packages "$service"
        if [ "$version" == "1.24.0-2ubuntu7" ]; then
            sudo apt install nginx=1.24.0-2ubuntu7 --allow-downgrades -y \
                nginx-common=1.24.0-2ubuntu7 \
                nginx-core=1.24.0-2ubuntu7 \
                libnginx-mod-http-image-filter=1.24.0-2ubuntu7 \
                libnginx-mod-http-xslt-filter=1.24.0-2ubuntu7 \
                libnginx-mod-mail=1.24.0-2ubuntu7 \
                libnginx-mod-stream=1.24.0-2ubuntu7 \
                libnginx-mod-http-geoip=1.24.0-2ubuntu7
        else
            sudo apt-get install --allow-downgrades -y \
                nginx-common="$version" \
                nginx-core="$version" \
                nginx="$version"
        fi
    fi
    elif ((download_source == 2)); then
        if [ "$service" == "apache" ]; then
            wget -P /tmp "$ftp_route/apache2/$version" &>/dev/null
            cd /tmp/$version
            sudo dpkg -i *.deb
        else
            wget -P /tmp "$ftp_route/nginx/$version" &>/dev/null
            cd /tmp/$version
            sudo dpkg -i *.deb
        fi
    else 
        return 1
    fi
}

get_service_versions() {
    local service="$1"
    local download_source="$2"
    if [ "$service" == "apache2" ]; then
        if ((download_source == 1)); then
            versions=($(apt-cache madison "$service" | awk '{print $3}'))
        else
        versions=($(wget -qO- "$ftp_route/$service/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+ubuntu[0-9.]+' | sort -u))
        fi
    elif [ "$service" == "nginx" ]; then
        if ((download_source == 1)); then
            versions=($(apt-cache madison "$service" | awk '{print $3}'))
        else 
        versions=($(wget -qO- "$ftp_route/$service/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+ubuntu[0-9.]+' | sort -u))
        fi
    fi
    echo "${versions[@]}"

}

get_tomcat_versions() {
    local version=$1
    local download_source=$2
    if ((download_source == 1)); then
        versions=($(wget -qO- "https://dlcdn.apache.org/tomcat/tomcat-$version/" | grep -oP 'v\d+\.\d+\.\d+' | sort -u | sed 's/v//g'))
    elif ((download_source == 2)); then
        versions=($(wget -qO- "$ftp_route/tomcat/$version/" | grep -oE 'apache-tomcat-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' | sort -u))
    else
        echo "Fuente de descarga no válida: $download_source"
        return 1
    fi
    echo "${versions[@]}"

}

verify_user_credentials() {
    local username="$1"
    local password="$2"
    echo "$password" | su - "$username" -c "exit" &>/dev/null
    return $?
}

install_tomcat() {
    local tomcat_version=$1
    local download_source=$2

    install_packages "tomcat"
    sudo rm /tmp/apache-tomcat*

    tomcat_version_list=($(get_tomcat_versions "$tomcat_version" $download_source))
    print_array "${tomcat_version_list[@]}"

    sudo systemctl stop tomcat 2>/dev/null
    sudo rm -rf /opt/tomcat/* 2>/dev/null
    sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat 2>/dev/null

    read -p "Ingresa la versión de Tomcat: " tomcat_version_choise
    while [[ $tomcat_version_choise -lt 0 || $tomcat_version_choise -ge ${#tomcat_version_list[@]} ]]; do
        read -p "Ingresa la version de Tomcat: " tomcat_version_choise
    done

    selected_version="${tomcat_version_list[$tomcat_version_choise]}"
    tar_name="apache-tomcat-${selected_version}.tar.gz"

    # Descargar desde fuente oficial o desde FTP
    if [[ "$download_source" == "1" ]]; then
        echo "Descargando desde Apache..."
       # echo "https://dlcdn.apache.org/tomcat/tomcat-$tomcat_version/v${tomcat_version_list[$tomcat_version_choise]}/bin/apache-tomcat-${tomcat_version_list[$tomcat_version_choise]}.tar.gz"
        wget -P /tmp "https://dlcdn.apache.org/tomcat/tomcat-$tomcat_version/v${tomcat_version_list[$tomcat_version_choise]}/bin/apache-tomcat-${tomcat_version_list[$tomcat_version_choise]}.tar.gz"
        sudo rm -rf /opt/tomcat/* 2>/dev/null
        sudo tar xzvf /tmp/apache-tomcat-$tomcat_version*tar.gz -C /opt/tomcat --strip-components=1
    elif [[ "$download_source" == "2" ]]; then
            echo "Descargando desde FTP..."
            echo "$selected_version"
            wget -P /tmp "$ftp_route/tomcat/$tomcat_version/$selected_version" &>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "Descarga exitosa: /tmp/$selected_version"
            fi
        sudo rm -rf /opt/tomcat/* 2>/dev/null
        sudo tar xzvf /tmp/$selected_version -C /opt/tomcat --strip-components=1
    else
        echo "Opción de fuente de descarga no válida: $download_source"
        return 1
    fi


    userName="admin"
    userPassword="admin"

    sudo truncate -s 0 /opt/tomcat/conf/tomcat-users.xml

    read -p "Ingresa el puerto de Tomcat: " tomcat_port
    while (sudo lsof -i :$tomcat_port &>/dev/null) || (is_port_in_common_ports $tomcat_port); do
        read -p "Ingresa un puerto: " tomcat_port
    done
    

    userName="admin"
    userPassword="admin"
    sudo truncate -s 0 /opt/tomcat/conf/tomcat-users.xml

    read -p "Ingresa el puerto de Tomcat: " tomcat_port
    while (sudo lsof -i :$tomcat_port &>/dev/null) || (is_port_in_common_ports $tomcat_port); do
        read -p "Ingresa un puerto: " tomcat_port
    done

    xmlstarlet ed --inplace -u '//Connector[@port="8080"]/@port' -v "$tomcat_port" /opt/tomcat/conf/server.xml

    cat <<EOF >> /opt/tomcat/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<!--
  <user username="admin" password="<must-be-changed>" roles="manager-gui"/>
  <user username="robot" password="<must-be-changed>" roles="manager-script"/>
-->
  <role rolename="manager-gui"/>
  <user username="manager" password="manager" roles="manager-gui"/>
  <role rolename="admin-gui"/>
  <user username="$userName" password="$userPassword" roles="admin-gui"/>
</tomcat-users>
EOF

    jdk_route=$(update-java-alternatives -l | grep openjdk | awk '{print $3}')

    sudo truncate -s 0 /opt/tomcat/webapps/manager/META-INF/context.xml 2>/dev/null
    cat <<EOF >> /opt/tomcat/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true">
    <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="strict" />
    <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap" />
</Context>
EOF

    sudo truncate -s 0 /opt/tomcat/webapps/host-manager/META-INF/context.xml 2>/dev/null
    cat <<EOF >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true">
    <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="strict" />
    <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap" />
</Context>
EOF
    read -p "Instalar certificado SSL? 1.-Si 2.-No: " install_ssl
    if [[ "$install_ssl" == "1" ]]; then
        certificate_key_path="/etc/ssl/private/tomcat-selfsigned.key"
    certificate_path="/etc/ssl/certs/tomcat-selfsigned.crt"

    sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048 \
        -subj "/C=MX/ST=Sinaloa/L=Momochis/O=SexomatasFC/OU=Software/CN=chochua"

    certificate_key_tomcat="/etc/ssl/certs/tomcat-selfsigned-cert.cert"
    keytool -genkey -alias $selected_version -keyalg RSA -keystore $certificate_key_tomcat
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
    fi

    sudo chown -R tomcat:tomcat /opt/tomcat/
    sudo chmod -R u+x /opt/tomcat/bin

    sudo truncate -s 0 /etc/systemd/system/tomcat.service 2>/dev/null
    sudo touch /etc/authbind/byport/$tomcat_port
    sudo chmod 500 /etc/authbind/byport/$tomcat_port
    sudo chown tomcat /etc/authbind/byport/$tomcat_port

    cat <<EOF >> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=$jdk_route"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/usr/bin/authbind --deep /opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start tomcat
    sudo systemctl enable tomcat
    sudo ufw allow "$tomcat_port"
    sudo systemctl status tomcat
    echo "Tomcat corriendo en el puerto $tomcat_port"
}

print_array() {
    local array=("$@")
    counter=0
    for element in "${array[@]}"; do
        echo "[$counter]. $element"
        ((counter++))
    done
}

package_installed() {
    local package="$1"
    if dpkg -l | grep -w "$package" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
Install_MiniKube(){
    sudo apt update -y
    sudo snap install kubectl --classic
    wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -O minikube
    chmod 755 minikube 
    sudo mv minikube /usr/local/bin/
    minikube version
    minikube start --memory=2048 --cpus=2
    minikube status
}
Create_Pods(){

    eval $(minikube docker-env)
    cat > secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: flaskapi-secret
type: Opaque
data:
  DB_USER: cm9vdA==
  DB_PASS: YWRtaW4=
  DB_NAME: Zmxhc2thcGlfZGI=
EOF
    kubectl apply -f secret.yaml
    cat > configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  confluence.cnf: |-
    [mysqld]
    character-set-server=utf8
    collation-server=utf8_bin
    default-storage-engine=InnoDB
    innodb_file_per_table=256M
    transaction-isolation=READ-COMMITTED

EOF
            kubectl apply -f configmap.yaml
    #Volumenes persistentes

    cat > mysql-pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-volume
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  hostPath:
    path: "/mnt/data/"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
EOF

    kubectl apply -f mysql-pvc.yaml

    # Crear cliente temporal de MySQL para inicializar la base de datos y la tabla 'teams'
    # El cliente se conecta al servicio MySQL desplegado en el clúster de Minikube
    # Se crea la base de datos 'flaskapi_db' si no existe, la tabla 'teams' y se insertan datos de ejemplo
    # El pod mysql-client se elimina automáticamente después de ejecutar los comandos
    # La contraseña de root es 'admin' (de acuerdo al secreto creado previamente)
    # Puedes modificar los valores de inserción según tus necesidades

    # kubectl run -i --rm mysql-client --image=mysql --restart=Never -- \
    # mysql -h mysql -uroot -padmin -e "
    # CREATE DATABASE IF NOT EXISTS flaskapi_db;
    # USE flaskapi_db;
    # CREATE TABLE IF NOT EXISTS teams (
    #     id INT AUTO_INCREMENT PRIMARY KEY,
    #     name VARCHAR(255) NOT NULL,
    #     group_number VARCHAR(255) NOT NULL,
    #     points INT DEFAULT 0,
    #     members INT DEFAULT 0,
    #     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    # );
    # INSERT INTO teams (name, group_number, points, members) VALUES
    # ('Team A', 'Group 1', 10, 5),
    # ('Team B', 'Group 1', 20, 6),
    # ('Team C', 'Group 2', 15, 4),
    # ('Team D', 'Group 2', 25, 7);
    # "

}
Show_Logs(){
    #Get all pods log in the default namespace
    kubectl get pods --namespace default -o jsonpath="{.items[*].metadata.name}"
}
Deploy_Apps(){
    eval $(minikube docker-env)
    mkdir -p flaskapi && cd flaskapi
    cat > flaskapi.py <<EOF
import os
from flask import Flask
from flaskext.mysql import MySQL

app = Flask(__name__)
mysql = MySQL()
app.config['MYSQL_DATABASE_USER'] = os.getenv('DB_USER')
app.config['MYSQL_DATABASE_PASSWORD'] = os.getenv('DB_PASS')
app.config['MYSQL_DATABASE_DB'] = os.getenv('DB_NAME')
app.config['MYSQL_DATABASE_HOST'] = 'mysql'
mysql.init_app(app)
@app.route('/')
def index():
    return "Hello, World!"
@app.route('/teams')
def teams():
    conn = mysql.connect()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM teams")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return str(rows)
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)


EOF
cat > requeriments.txt <<EOF
Flask==1.0.3
Flask-MySQL==1.4.0
PyMySQL==0.9.3
PyMySQL[rsa]
EOF

cat > Dockerfile <<EOF
FROM python:3.6-slim
RUN apt-get clean && apt-get -y update && \
    apt-get -y install build-essential
WORKDIR /app
COPY requeriments.txt /app/requeriments.txt
RUN pip install --no-cache-dir -r /app/requeriments.txt
COPY . .
EXPOSE 5000
CMD ["python", "flaskapi.py"]
EOF
docker build -t flask-api .
cd ..

cat > mysql-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: flaskapi-secret
              key: DB_PASS
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
        - name: mysql-config-volume
          mountPath: /etc/mysql/conf.d
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
      - name: mysql-config-volume
        configMap:
          name: mysql-config

EOF
    kubectl apply -f mysql-deployment.yaml
    #Services

    cat>mysql-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
    name: mysql
spec:
    selector:
        app: mysql
    ports:
    - port: 3306
      protocol: TCP
      name: mysql
    type: ClusterIP

EOF
    kubectl apply -f mysql-service.yaml 
    cat > flaskapi-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
    name: flaskapi-deployment
spec:
    replicas: 1
    selector:
        matchLabels:
            app: flaskapi
    template:
        metadata:
            labels:
                app: flaskapi
        spec:
            containers:
            - name: flaskapi
              image: flask-api
              imagePullPolicy: Never
              ports:
              - containerPort: 5000
              env:
                  - name: DB_USER
                    valueFrom:
                        secretKeyRef:
                            name: flaskapi-secret
                            key: DB_USER
                  - name: DB_PASS
                    valueFrom:
                        secretKeyRef:
                            name: flaskapi-secret
                            key: DB_PASS
                  - name: DB_NAME
                    valueFrom:
                        secretKeyRef:
                            name: flaskapi-secret
                            key: DB_NAME
EOF

    cat > flaskapi-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
    name: flaskapi-service
spec:
    type: LoadBalancer
    selector:
        app: flaskapi
    ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000

EOF
    kubectl apply -f flaskapi-service.yaml
    kubectl apply -f flaskapi-deployment.yaml
    minikube service flaskapi-service --url
    minikube service mysql --url
    echo "Aplicaciones desplegadas correctamente."
}