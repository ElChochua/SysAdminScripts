#!/bin/bash
sudo apt-get update -y
sudo apt-get install openssh-server -y
sudo ufw allow ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
echo "El servidor SSH ha sido instalado correctamente"