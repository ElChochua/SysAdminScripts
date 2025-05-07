#!/bin/bash
source /media/sf_shared/Functions.sh
sudo apt-get update -y
sudo apt install bind9 bind9-utils -y
echo "Dando permisos a Bind9"
sudo ufw allow bind9
read -p "Ingrese la direccion IP raiz: " root_ip
echo "Configraicion de zones"
read -p "Ingrese el nombre de su dominio: " domain_name
truncate -s 0 /etc/bind/named.conf.options
echo options { >> /etc/bind/named.conf.options
echo '	'"directory \"/var/cache/bind\""';' >> /etc/bind/named.conf.options
echo '  ' listen-on { any\; }\; >> /etc/bind/named.conf.options
echo '  ' allow-query { localhost\; $root_ip\; }\; >> /etc/bind/named.conf.options
echo '  ' forwarders { >> /etc/bind/named.conf.options
echo '      ' 8.8.8.8\; >> /etc/bind/named.conf.options
echo '      ' 8.8.4.4\; >> /etc/bind/named.conf.options
echo '  ' }\; >> /etc/bind/named.conf.options
echo '  ' dnssec-validation no\; >> /etc/bind/named.conf.options
echo '  ' // listen-on-v6 { any\; }\; >> /etc/bind/named.conf.options
echo }\; >> /etc/bind/named.conf.options
echo "Configuracion de Bind9 realizada"

truncate -s 0 /etc/default/named
echo '#' run resolvconf? >> /etc/default/named
echo RESOLVCONF=no >> /etc/default/named
echo '#' startup options for the server >> /etc/default/named
echo OPTIONS="-u bind -4" >> /etc/default/named
sleep 1
echo "Configuracion de Bind9 realizada"

ip_reverse_zone=$(remove_last_byte_and_rev $root_ip)
sudo mkdir -p /etc/bind/zones/
truncate -s 0 /etc/bind/named.conf.local

sleep 1
sudo truncate -s 0 /etc/bind/zones/db.$domain_name
sudo truncate -s 0 /etc/bind/zones/db.$ip_reverse_zone
sudo truncate -s 0 /etc/bind/named.conf.local
echo zone \"$domain_name\" { >> /etc/bind/named.conf.local
echo '  ' type master\; >> /etc/bind/named.conf.local
echo '  ' file \"/etc/bind/zones/db.$domain_name\"\; >> /etc/bind/named.conf.local
echo }\; >> /etc/bind/named.conf.local

echo zone \"$ip_reverse_zone.in-addr.arpa\" { >> /etc/bind/named.conf.local
echo '  ' type master\; >> /etc/bind/named.conf.local
echo '  ' file \"/etc/bind/zones/db.$ip_reverse_zone\"\; >> /etc/bind/named.conf.local
echo }\; >> /etc/bind/named.conf.local
last_byte=$(get_last_byte $(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+'))
local_ip=$(ip -4 addr show enp0s8 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+')
sudo truncate -s 0 /etc/bind/zones/db.$domain_name

echo "\$TTL	604800" >> /etc/bind/zones/db.$domain_name
echo "@	IN 			SOA $domain_name. admin.$domain_name. (" >> /etc/bind/zones/db.$domain_name
echo "			      2		; Serial" >> /etc/bind/zones/db.$domain_name
echo "			 604800		; Refresh" >> /etc/bind/zones/db.$domain_name
echo "			  86400		; Retry" >> /etc/bind/zones/db.$domain_name
echo "			2419200		; Expire" >> /etc/bind/zones/db.$domain_name
echo "			 604800 )	; Negative Cache TTL" >> /etc/bind/zones/db.$domain_name
echo ";" >> /etc/bind/zones/db.$domain_name
echo " " >> /etc/bind/zones/db.$domain_name
echo "@  IN NS  $domain_name." >> /etc/bind/zones/db.$domain_name
echo "@  IN A  $local_ip" >> /etc/bind/zones/db.$domain_name
echo "ns  IN A  $local_ip" >> /etc/bind/zones/db.$domain_name
echo "www  IN A  $local_ip" >> /etc/bind/zones/db.$domain_name
echo "server  IN CNAME  $domain_name." >> /etc/bind/zones/db.$domain_name

sudo truncate -s 0 /etc/bind/zones/db.$ip_reverse_zone

echo "\$TTL	604800" >> /etc/bind/zones/db.$ip_reverse_zone
echo "@	IN SOA $domain_name. admin.$domain_name. (" >> /etc/bind/zones/db.$ip_reverse_zone
echo "			      2		; Serial" >> /etc/bind/zones/db.$ip_reverse_zone
echo "			 604800		; Refresh" >> /etc/bind/zones/db.$ip_reverse_zone
echo "			  86400		; Retry" >> /etc/bind/zones/db.$ip_reverse_zone
echo "			2419200		; Expire" >> /etc/bind/zones/db.$ip_reverse_zone
echo "			 604800 )		; Negative Cache TTL" >> /etc/bind/zones/db.$ip_reverse_zone
echo ";" >> /etc/bind/zones/db.$ip_reverse_zone
echo " " >> /etc/bind/zones/db.$ip_reverse_zone
echo "  IN NS  $domain_name." >> /etc/bind/zones/db.$ip_reverse_zone
echo $last_byte" IN PTR  server.$domain_name" >> /etc/bind/zones/db.$ip_reverse_zone

sudo systemctl restart bind9
sudo systemctl status bind9



