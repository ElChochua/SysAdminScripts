#!/bin/bash
reverse_ip() {
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        octetos=( ${ip//./ } )
        echo "${octetos[3]}.${octetos[2]}.${octetos[1]}.${octetos[0]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}
remove_last_byte_and_rev(){
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[2]}.${byte[1]}.${byte[0]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}

get_last_byte(){
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[3]}"
    else
        echo "Error: Dirección IP inválida"
        return 1
    fi
}
    sudo sed -i '9i\       ServerName correo.chochua.local' /etc/apache2/sites-available/round.conf
