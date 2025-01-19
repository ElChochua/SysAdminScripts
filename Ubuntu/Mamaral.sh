#!/bin/bash

# Instalamos la paquetería de VS FTPD
sudo apt install vsftpd
clear

# Creamos la carpeta General o el nombre que quiera el usuario
echo 'Nombre de la carpeta principal: '
read mainFolder

sudo mkdir /home/FTP # Primero se crea la carpeta raíz
sudo mkdir /home/FTP/"$mainFolder" # Después la carpeta principal/general

# Configuramos los permisos a las carpetas
sudo chmod -R 777 /home/FTP/"$mainFolder"

# Creamos los grupos y sus carpetas correspondientes
# Creamos el primer grupo
echo 'Nombre de un grupo A: '
read groupA
sudo groupadd "$groupA"
sudo mkdir /home/"$groupA"

# Creamos el segundo grupo
echo 'Nombre de un grupo B: ' # Corregido el mensaje
read groupB
sudo groupadd "$groupB"
sudo mkdir /home/"$groupB"

# Le asignamos los permisos pertinentes
sudo chmod 770 /home/"$groupA"
sudo chgrp -R $groupA /home/"$groupA"
sudo chown :$groupA /home/"$groupA"

sudo chmod 770 /home/"$groupB"
sudo chgrp -R $groupB /home/"$groupB"
sudo chown :$groupB /home/"$groupB"

# Le solicitamos al usuario cuántos usuarios
echo ' '
echo '¿Cuántos usuarios necesita?'
read userCount
echo ' '

for ((i=1; i<=$userCount; i++)) 
do
    # Ingresar el nombre del usuario
    echo "Ingrese el nombre del usuario $i: "
    read username

    # Le pedimos la contraseña para ese usuario
    echo "Ingrese la contraseña del usuario $username"
    read -s password

    # Creamos al usuario
    sudo useradd -m "$username" 
    echo "$username:$password" | sudo chpasswd

    # Le decimos a qué grupo se unirá
    echo 'Grupo al que quiere ingresar: '
    read selectGroup

	# Añadimos el usuario al grupo
    sudo usermod -a -G $selectGroup $username
	
	# Le creamos las carpetas al usuario
    sudo mkdir /home/$username/General
    sudo mkdir /home/$username/$selectGroup
    sudo mkdir /home/$username/Personal
	
	# Le asignamos permisos a la carpeta personal y su dueño (owner)
    sudo chmod 700 /home/$username/Personal
    sudo chown $username:$username /home/$username/Personal
	
	# Lo mismo que antes
    sudo chmod 700 /home/$username/General
    sudo chown $username:$username /home/$username/General
	
	# Tambor
    sudo chmod 700 /home/$username/$selectGroup
    sudo chown $username:$username /home/$username/$selectGroup
	
    sudo mount --bind -R /home/FTP/General /home/$username/General
    sudo mount --bind -R /home/$selectGroup /home/$username/$selectGroup
done

# Reiniciamos el servicio para que todo quede bien
sudo systemctl restart vsftpd
sudo systemctl status vsftpd