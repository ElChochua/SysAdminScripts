#!/bin/bash
#sudo apt install vsftpd
source /media/sf_Ubuntu/Functions.sh

clear
sudo mkdir -p /home/FTP 2>/dev/null
sudo chmod -R 755 /home/FTP
sudo mkdir -p /home/FTP/General 2>/dev/null

# Crear un grupo común para todos los usuarios FTP
sudo groupadd ftpusers 2>/dev/null
sudo chgrp ftpusers /home/FTP/General
# Establecer SGID bit y permisos completos para que todos los usuarios puedan crear y acceder
sudo chmod 2777 /home/FTP/General

sudo truncate -s 0 /etc/vsftpd.conf
{
    echo "listen=NO"
    echo "listen_ipv6=YES"
    echo "anonymous_enable=YES"
    echo "anon_root=/home/FTP"
    echo "anon_upload_enable=NO"
    echo "write_enable=YES"
    echo "local_enable=YES"
    echo "chroot_local_user=YES"
    echo "allow_writeable_chroot=YES"
    echo "dirmessage_enable=YES"
    echo "use_localtime=YES"
    echo "xferlog_enable=YES"
    echo "connect_from_port_20=YES"
    echo "secure_chroot_dir=/var/run/vsftpd/empty"
    echo "pam_service_name=vsftpd"
    echo "local_umask=002"  # Asegura que los archivos creados tengan permisos 664 y directorios 775
} >> /etc/vsftpd.conf

groupA_name="reprobados"
groupB_name="recursadores"

sudo groupadd $groupA_name 2>/dev/null
sudo mkdir -p /home/$groupA_name 2>/dev/null
sudo groupadd $groupB_name 2>/dev/null
sudo mkdir -p /home/$groupB_name 2>/dev/null

# Establecer SGID y permisos apropiados en las carpetas de grupos
sudo chmod 2770 /home/$groupA_name
sudo chmod 2770 /home/$groupB_name
sudo chgrp $groupA_name /home/$groupA_name
sudo chgrp $groupB_name /home/$groupB_name
sudo chown :$groupA_name /home/$groupA_name
sudo chown :$groupB_name /home/$groupB_name
groups=($groupA_name $groupB_name)

read -p "Número de usuarios a agregar: " user_count

for ((i = 1; i <= user_count; i++)); do
    while true; do
        read -p "$i. Ingresa el nombre del usuario: " user_name
        
        if validate_userName "$user_name" && ! user_exists "$user_name"; then
            
            echo -e "\nGrupos disponibles \n0.-${groups[0]}\n1.-${groups[1]}"
            read -p "$i. Elija el grupo al que pertenece: " option

            if [[ "$option" =~ ^[0-1]$ ]]; then
                user_group=${groups[$option]}

                if user_in_reprobados_o_recursados "$user_name"; then
                    echo "El usuario ya pertenece a 'reprobados' o 'recursados'. Se omitirá."
                else
                    read -s -p "$i. Ingresa la contraseña: " user_password
                    echo ""
                    sudo useradd -m "$user_name"
                    echo "$user_name:$user_password" | sudo chpasswd
                    sudo usermod -a -G "$user_group" "$user_name"
                    # Agregar el usuario al grupo ftpusers
                    sudo usermod -a -G "ftpusers" "$user_name"

                    sudo mkdir -p "/home/$user_name/General" "/home/$user_name/Personal" "/home/$user_name/$user_group"

                    sudo chmod 775 "/home/$user_name/General"
                    sudo chmod 700 "/home/$user_name/Personal"
                    sudo chmod 775 "/home/$user_name/$user_group"

                    sudo chown "$user_name:$user_name" "/home/$user_name/General" "/home/$user_name/Personal"
                    sudo chown "$user_name:$user_group" "/home/$user_name/$user_group"

                    # Montar directorios compartidos
                    sudo mount --bind "/home/FTP/General" "/home/$user_name/General"
                    sudo mount --bind "/home/$user_group" "/home/$user_name/$user_group"

                    echo "Usuario '$user_name' creado y asignado al grupo '$user_group'."
                fi
            else
                echo "Elija una opción válida"
            fi
            break
        elif user_exists "$user_name"; then
            echo "El usuario '$user_name' ya existe."
            echo "El usuario ya existe"
            if ! user_in_reprobados_o_recursados "$user_name"; then
                echo -e "\nEl usuario no pertenece a ninguno de los grupos válidos."
                echo -e "\nGrupos disponibles \n0.-${groups[0]}\n1.-${groups[1]}"
                read -p "$i. Elija el grupo al que desea agregarlo: " option
                if [[ "$option" =~ ^[0-1]$ ]]; then
                    user_group=${groups[$option]}
                    sudo usermod -a -G "$user_group" "$user_name"
                    # Agregar el usuario al grupo ftpusers también
                    sudo usermod -a -G "ftpusers" "$user_name"
                    
                    sudo mkdir -p "/home/$user_name/General" "/home/$user_name/Personal" "/home/$user_name/$user_group"
                    sudo chmod -R 775 "/home/$user_name/General"
                    sudo chmod 700 "/home/$user_name/Personal"
                    sudo chmod 775 "/home/$user_name/$user_group"
                    sudo chown "$user_name:$user_name" "/home/$user_name/General" "/home/$user_name/Personal"
                    sudo chown "$user_name:$user_group" "/home/$user_name/$user_group"
                    sudo mount --bind "/home/FTP/General" "/home/$user_name/General"
                    sudo mount --bind "/home/$user_group" "/home/$user_name/$user_group"
                    echo "Usuario '$user_name' agregado al grupo '$user_group'."
                else
                    echo "Elija una opción válida."
                fi
            fi
            break
        else
            echo "Nombre de usuario inválido"
        fi
    done
done

read -p "Deseas agregar SSL a tu servidor FTP? (y/n): " ssl
if [ "$ssl" != "N" ] && [ "$ssl" != "n" ]; then
    source /media/sf_shared/SSLFtp.sh
fi

sudo systemctl restart vsftpd
sudo systemctl status vsftpd