#!/bin/bash
#sudo apt install vsftpd
source /media/sf_shared/Functions.sh

clear
sudo mkdir -p /home/FTP 2>/dev/null
# Grant read and execute permissions to the ftpusers group on the base FTP directory
sudo chown root:ftpusers /home/FTP
sudo chmod 775 /home/FTP

sudo mkdir -p /home/FTP/General 2>/dev/null
sudo mkdir -p /home/FTP/General/Resources 2>/dev/null

sudo groupadd ftpusers 2>/dev/null

# Create resource subdirectories and copy files
for dir in apache2 nginx tomcat; do
    sudo mkdir -p "/home/FTP/General/Resources/$dir"
    sudo chmod -R 755 "/home/FTP/General/Resources/$dir"
    sudo chown -R root:ftpusers "/home/FTP/General/Resources/$dir"
    sudo cp -r "/media/sf_shared/Resources/$dir/"* "/home/FTP/General/Resources/$dir/" 2>/dev/null
done

# Assign ftpusers group to the content and set appropriate permissions
sudo chgrp -R ftpusers /home/FTP/General
sudo chmod -R 775 /home/FTP/General

# Ensure group access from General to Resources
sudo chgrp -R ftpusers /home/FTP/General/Resources
sudo chmod -R 2755 /home/FTP/General/Resources
sudo find /home/FTP/General/Resources -type d -exec chmod g+s {} \;

sudo chmod 2755 /home/FTP/General/Resources

read -p "Install SSL certificate 1.-Si 2.-No " SSL_option
if (( SSL_option == 1 )); then
    certificate_key_path="/etc/ssl/private/vsftpd.pem"
    certificate_path="/etc/ssl/certs/vsftpd-selfsigned.crt"
    sudo openssl req -x509 -nodes -keyout $certificate_key_path -out $certificate_path -days 365 -newkey rsa:2048 \
        -subj "/C=MX/ST=Sinaloa/L=Momochis/O=SexomatasFC/OU=Software/CN=chochua"
    sudo truncate -s 0 /etc/vsftpd.conf
    sudo tee /etc/vsftpd.conf > /dev/null <<EOF
listen=NO
listen_ipv6=YES
anonymous_enable=YES
anon_root=/home/FTP
anon_upload_enable=NO
write_enable=YES
local_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
local_umask=022
rsa_cert_file=${certificate_path}
rsa_private_key_file=${certificate_key_path}
ssl_enable=YES
allow_anon_ssl=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
EOF
else
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
        echo "local_umask=022"
    } >> /etc/vsftpd.conf
fi

groupA_name="reprobados"
groupB_name="recursadores"
groups=($groupA_name $groupB_name)

sudo groupadd $groupA_name 2>/dev/null
sudo mkdir -p /home/$groupA_name 2>/dev/null
sudo chmod 1775 /home/$groupA_name
sudo chgrp $groupA_name /home/$groupA_name

sudo groupadd $groupB_name 2>/dev/null
sudo mkdir -p /home/$groupB_name 2>/dev/null
sudo chmod 1775 /home/$groupB_name
sudo chgrp $groupB_name /home/$groupB_name

# Permission hook
sudo cat <<EOF > /etc/vsftpd.hook
#!/bin/bash
find /home/reprobados -mindepth 1 -maxdepth 1 -type d -exec chmod 755 {} \;
find /home/recursadores -mindepth 1 -maxdepth 1 -type d -exec chmod 755 {} \;
EOF

sudo chmod +x /etc/vsftpd.hook
(crontab -l 2>/dev/null; echo "*/5 * * * * /etc/vsftpd.hook") | sort | uniq | crontab -

# Create users
read -p "Cuantos usuarios deseas añadir? : " user_count

for ((i = 1; i <= user_count; i++)); do
    while true; do
        read -p "$i. username: " user_name
        
        if validate_userName "$user_name" && ! user_exists "$user_name"; then
            echo -e "\Grupos disponibles \n0.-${groups[0]}\n1.-${groups[1]}"
            read -p "$i. Escoge a que grupo pertenece: " option

            if [[ "$option" =~ ^[0-1]$ ]]; then
                user_group=${groups[$option]}

                if user_in_reprobados_o_recursados "$user_name"; then
                    echo "El usuario ya pertenece al grupo se omitira."
                else
                    read -s -p "$i. Enter the password: " user_password
                    echo ""
                    sudo useradd -m "$user_name"
                    echo "$user_name:$user_password" | sudo chpasswd
                    sudo usermod -a -G "$user_group,ftpusers" "$user_name"

                    sudo mkdir -p "/home/$user_name/General" "/home/$user_name/Personal" "/home/$user_name/$user_group"
                    sudo chmod 775 "/home/$user_name/General"
                    sudo chmod 700 "/home/$user_name/Personal"
                    sudo chmod 775 "/home/$user_name/$user_group"

                    sudo chown "$user_name:$user_name" "/home/$user_name/General" "/home/$user_name/Personal"
                    sudo chown "$user_name:$user_group" "/home/$user_name/$user_group"

                    sudo mount --bind "/home/FTP/General" "/home/$user_name/General"
                    sudo mount --bind "/home/$user_group" "/home/$user_name/$user_group"

                    echo "User '$user_name' created and assigned to group '$user_group'."
                fi
            else
                echo "Choose a valid option"
            fi
            break

        elif user_exists "$user_name"; then
            echo "El usuario: '$user_name' ya existe."

            if ! user_in_reprobados_o_recursados "$user_name"; then
                echo -e "\nGrupos disponibles \n0.-${groups[0]}\n1.-${groups[1]}"
                read -p "$i. Escoge al grupo donde lo quieres añadir: " option

                if [[ "$option" =~ ^[0-1]$ ]]; then
                    user_group=${groups[$option]}
                    sudo usermod -a -G "$user_group,ftpusers" "$user_name"

                    sudo mkdir -p "/home/$user_name/General" "/home/$user_name/Personal" "/home/$user_name/$user_group"
                    sudo chmod 775 "/home/$user_name/General"
                    sudo chmod 700 "/home/$user_name/Personal"
                    sudo chmod 775 "/home/$user_name/$user_group"

                    sudo chown "$user_name:$user_name" "/home/$user_name/General" "/home/$user_name/Personal"
                    sudo chown "$user_name:$user_group" "/home/$user_name/$user_group"

                    sudo mount --bind "/home/FTP/General" "/home/$user_name/General"
                    sudo mount --bind "/home/$user_group" "/home/$user_name/$user_group"

                    echo "User '$user_name' agregado al grupo:  '$user_group'."
                else
                    echo "Escoge una opcion valida."
                fi
            fi
            break

        else
            echo "Invalid username"
        fi
    done
done

# Execute initial permission hook
sudo /etc/vsftpd.hook
read -p "Quieres agregar un servicio http? 1.-Si 2.-No " http_option
if (( http_option == 1 )); then
    source /media/sf_shared/HTTPInstaller.sh
else
    echo "No se agregara un servicio http."
fi
sudo systemctl restart vsftpd
sudo systemctl status vsftpd