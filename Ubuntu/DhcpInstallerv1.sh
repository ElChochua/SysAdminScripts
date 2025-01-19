#!/bin/bash
apt-get install isc-dhcp-server
#Ruta Default /etc/dhcp/dhcpd.conf
subnet=""
netmask=""
rango=""
nombreDominio=""
puertaEnlace=""
mascaraSubNet=""
dns=""
tiempoBusqueda=""
ipAdaptador=""

echo "Ingresa el SubNet"
read subnet
echo "ingresa la mascara de red"
read netmask
echo "Ingresa el rango ej: 192.168.1.100 255.255.255.0"
read rango
echo "Ingresa el nombre del dominio"
read nombreDominio
echo "Ingresa la puerta de enlace"
read puertaEnlace
echo "Ingresa la mascara de subnet"
read mascaraSubNet
echo "Ingresa el servidor DNS"
read dns
sudo truncate -s 0 /etc/dhcp/dhcpd.conf

echo "subnet $subnet netmask $netmask{
              range $rango;
              option domain-name \"$nombreDominio\";
              option routers $puertaEnlace;
              option subnet-mask $mascaraSubNet;
              option domain-name-servers $dns;
              default-lease-time 3600;
              max-lease-time 86400;
}">>/etc/dhcp/dhcpd.conf

dhcpd -t -cf /etc/dhcp/dhcpd.conf

echo "Se ha realizado la configuraciÃ²n se reiniciara el servidor dhcp"

service isc-dhcp-server restart
service isc-dhcp-server status

