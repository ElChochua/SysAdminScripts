#!/bin/bash
source /media/sf_shared/Functions.sh
version="9"
#    sudo apt-get install --allow-downgrades -y \
#        nginx=$version \
#        nginx-bin=$version \
#        nginx-data=$version \
#        nginx-utils=$version

#store the version array in a variable
#versions=($(get_tomcat_versions "$version"))
#echo "Available versions: ${versions[@]}"
    read -p "Ingresa un puerto: " port
while (sudo lsof -i :$port &>/dev/null) || (is_port_in_common_ports $port); do
    read -p "Ingresa un puerto: " port
done