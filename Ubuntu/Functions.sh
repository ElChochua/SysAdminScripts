#!/bin/bash

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
            return 0 ;;
        *)
            return 1 ;;
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
            return 0  # El usuario está en "reprobados" o "recursados"
        fi
    done
    return 1  # No pertenece a esos grupos
}
install_packages(){
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
            if (! package_installed "$package" ); then
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
    apt --fix-broken install>>/dev/null
}
install_service(){
    local service="$1"
    local version="$2"
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
                nginx-core="$version"  \
                nginx="$version"
        fi
    fi
}
get_service_versions(){
    local service="$1"
    if [ "$service" == "apache2" ]; then
        versions=($(apt-cache madison "$service" | awk '{print $3}'))
        echo "${versions[@]}"
    elif [ "$service" == "nginx" ]; then
        versions=($(apt-cache madison "$service" | awk '{print $3}'))
        echo "${versions[@]}"
    fi
}
get_tomcat_versions() {
    local version=$1
    versions=($(curl -s "https://dlcdn.apache.org/tomcat/tomcat-$version/" | grep -oP "(?<=v)$version\.\d+\.\d+" | sort -V | uniq))
    echo "${versions[@]}"
}
install_tomcat(){
    local tomcat_version=$1
    install_packages "tomcat"
    sudo rm /tmp/apache-tomcat* 
    tomcat_version_list=($(get_tomcat_versions "$tomcat_version"))
    print_array "${tomcat_version_list[@]}"
    sudo systemctl stop tomcat 2> /dev/null
    sudo rm -rf /opt/tomcat/*  2> /dev/null

    sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat 2> /dev/null

    read -p "Ingresa la versión de Tomcat: " tomcat_version_choise
    while [[ $tomcat_version_choise -lt 0 || $tomcat_version_choise -ge ${#tomcat_version_list[@]} ]]; do
        read -p "Ingresa la version de Tomcat: " tomcat_version_choise
    done
    sudo rm -rf /opt/tomcat/* 2> /dev/null
    echo "https://dlcdn.apache.org/tomcat/tomcat-$tomcat_version/v${tomcat_version_list[$tomcat_version_choise]}/bin/apache-tomcat-${tomcat_version_list[$tomcat_version_choise]}.tar.gz"
    wget -P /tmp "https://dlcdn.apache.org/tomcat/tomcat-$tomcat_version/v${tomcat_version_list[$tomcat_version_choise]}/bin/apache-tomcat-${tomcat_version_list[$tomcat_version_choise]}.tar.gz"
    sudo tar xzvf /tmp/apache-tomcat-$tomcat_version*tar.gz -C /opt/tomcat --strip-components=1
    userName="admin"
    userPassword="admin"
    sudo truncate -s 0 /opt/tomcat/conf/tomcat-users.xml
    read -p "Ingresa el puerto de Tomcat: " tomcat_port
    while (sudo lsof -i :$tomcat_port &>/dev/null) || (is_port_in_common_ports $tomcat_port); do
        read -p "Ingresa un puerto: " tomcat_port
    done
    xmlstarlet ed --inplace -u '//Connector[@port="8080"]/@port' -v "$tomcat_port" /opt/tomcat/conf/server.xml
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
  <user username=\"$userName\" password=\"$userPassword\" roles=\"admin-gui\"/>
</tomcat-users>
" >> /opt/tomcat/conf/tomcat-users.xml

jdk_route=$(update-java-alternatives -l | grep openjdk | awk '{print $3}')
sudo truncate -s 0 /opt/tomcat/webapps/manager/META-INF/context.xml 2> /dev/null
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "<Context antiResourceLocking=\"false\" privileged=\"true\">" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "    <CookieProcessor className=\"org.apache.tomcat.util.http.Rfc6265CookieProcessor\"" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "                    sameSiteCookies=\"strict\" />" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "    <Manager sessionAttributeValueClassNameFilter=\"java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\\$LruCache(?:\\\$1)?|java\\.util\\.(?:Linked)?HashMap\" />" >> /opt/tomcat/webapps/manager/META-INF/context.xml
echo "</Context>" >> /opt/tomcat/webapps/manager/META-INF/context.xml


sudo truncate -s 0 /opt/tomcat/webapps/host-manager/META-INF/context.xml 2> /dev/null
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "<Context antiResourceLocking=\"false\" privileged=\"true\">" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "    <CookieProcessor className=\"org.apache.tomcat.util.http.Rfc6265CookieProcessor\" sameSiteCookies=\"strict\" />" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "    <Manager sessionAttributeValueClassNameFilter=\"java\\.lang\\.(?:Boolean|Integer|Long|Number|String)|org\\.apache\\.catalina\\.filters\\.CsrfPreventionFilter\\\$LruCache(?:\\\$1)?|java\\.util\\.(?:Linked)?HashMap\" />" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
echo "</Context>" >> /opt/tomcat/webapps/host-manager/META-INF/context.xml
    sudo chown -R tomcat:tomcat /opt/tomcat/
    sudo chmod -R u+x /opt/tomcat/bin
sudo truncate -s 0 /etc/systemd/system/tomcat.service 2> /dev/null
sudo touch /etc/authbind/byport/$tomcat_port
sudo chmod 500 /etc/authbind/byport/$tomcat_port
sudo chown tomcat /etc/authbind/byport/$tomcat_port

echo "[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=\"JAVA_HOME=$jdk_route\"
Environment=\"JAVA_OPTS=-Djava.security.egd=file:///dev/urandom\"
Environment=\"CATALINA_BASE=/opt/tomcat\"
Environment=\"CATALINA_HOME=/opt/tomcat\"
Environment=\"CATALINA_PID=/opt/tomcat/temp/tomcat.pid\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"

ExecStart=/usr/bin/authbind --deep /opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/tomcat.service
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo ufw allow "$tomcat_port"
sudo systemctl status tomcat
echo "Tomcat corriendo en el puerto $tomcat_port"
}
print_array(){
    local array=("$@")
    counter=0
    for element in "${array[@]}"; do
        echo "[$counter]. $element"
        ((counter++))
    done
}
package_installed(){
    local package="$1"
    if dpkg -l | grep -w "$package" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
