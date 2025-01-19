#!/bin/bash
#sudo apt-get upgrade
#sudo apt-get update
if ! apt list --installed 2>/dev/null | grep -qw "isc-dhcp-server";then
    echo "Instalando DHCP"
    sudo apt install isc-dhcp-server
    clear
fi
if ! apt list --installed 2>/dev/null |grep -qw "net-tools"; then
    echo "Instalando IfConfig"
    sudo apt install net-tools
    clear
fi
truncate -s 0 /etc/dhcp/dhcpd.conf

read -p "Asigna una direccion al adaptador de red" ipAdaptador
sudo truncate -s 0 /etc/netplan/50-cloud-init.yaml
echo "network:">>/etc/netplan/50-cloud-init.yaml
echo " ethernets:">>/etc/netplan/50-cloud-init.yaml
echo "  enp0s3:">>/etc/netplan/50-cloud-init.yaml
echo "   dhcp4: yes">>/etc/netplan/50-cloud-init.yaml
echo "  enp0s8:">>/etc/netplan/50-cloud-init.yaml
echo "   dhcp4: no">>/etc/netplan/50-cloud-init.yaml
echo "   addresses: [$ipAdaptador/24]">>/etc/netplan/50-cloud-init.yaml
echo " version: 2">>/etc/netplan/50-cloud-init.yaml
sudo netplan apply

sudo truncate -s 0 /etc/default/isc-dhcp-server
echo "INTERFACESv4="enp0s8"">>/etc/default/isc-dhcp-server
echo "INTERFACESv6=""">>/etc/default/isc-dhcp-server

read -p "Ingresa la familia de la red: " ipFam
read -p "Ingresa la mascara de la red: " ipMask
read -p "Ingresa rango inicial de la red" initialRange
read -p "Ingresa rango final de la red" finalRange
read -p "Ingresa la puerta de enlace: " ipGateway
read -p "Ingresa la direccion del servidor DNS: " dns
read -p "Ingresa el nombre del dominio" domainName

sudo truncate -s 0 /etc/dhcp/dhcpd.conf
echo subnet $ipFam netmask $ipMask { >> /etc/dhcp/dhcpd.conf
echo ' ' range $initialRange $finalRange\; >> /etc/dhcp/dhcpd.conf
echo ' ' option routers $ipGateway\; >> /etc/dhcp/dhcpd.conf
echo ' ' option subnet-mask $ipMask\; >> /etc/dhcp/dhcpd.conf
echo ' ' option domain-name-servers $dns\; >> /etc/dhcp/dhcpd.conf
echo ' ' option domain-name "$domainName"\; >> /etc/dhcp/dhcpd.conf
echo ' ' default-lease-time 3600; >> /etc/dhcp/dhcpd.conf
echo ' 'max-lease-time 86400; >> /etc/dhcp/dhcpd.conf
echo } >> /etc/dhcp/dhcpd.conf
dhcpd -t -cf /etc/dhcp/dhcpd.conf
echo "Se ha realizado la configuraciòn se reiniciara el servidor dhcp"
service isc-dhcp-server restart
service isc-dhcp-server status
