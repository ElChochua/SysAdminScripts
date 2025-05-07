#!/bin/bash
sudo apt -y update
DOMAIN_IP="192.168.1.5"
DOMAIN_NAME="reprobados.com"
TARGET_NAME="WindowsS"
wget https://github.com/BeyondTrust/pbis-open/releases/download/9.1.0/pbis-open-9.1.0.551.linux.x86_64.deb.sh
chmod +x pbis-open-9.1.0.551.linux.x86_64.deb.sh
sudo ./pbis-open-9.1.0.551.linux.x86_64.deb.sh
sudo truncate -s 0 /etc/resolv.conf
echo "
    nameserver 10.0.2.3
    nameserver $DOMAIN_IP
    search $DOMAIN_NAME
"
#add the domain name in the hosts file
echo "$DOMAIN_IP $DOMAIN_NAME" | sudo tee -a /etc/hosts
sudo /opt/pbis/bin/domainjoin-cli join REPROBADOS.COM