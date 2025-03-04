#!/bin/sh
reverse_ip() {
    local ip=$1
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        byte=( ${ip//./ } )
        echo "${byte[3]}.${byte[2]}.${byte[1]}.${byte[0]}"
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
validate_userName(){
    local user_name=$1
    if [[ "$user_name" =~ ^[a-z0-9_-]{3,15}$ ]]; then
        return 0
    else
        return 1
    fi
}
user_exists(){
    local user_name=$1
    if id -u $user_name >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
group_exists(){
    local group_name=$1
    if getent group $group_name >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
user_in_group(){
    local user_name=$1
    local group_name=$2
    if groups $user_name | grep &>/dev/null "\b$group_name\b"; then
        return 0
    else
        return 1
    fi
}
#function to check if the user is already in a group different from the one we want to add it to
user_in_reprobados_o_recursados() {
    local usuario="$1"
    grupos_usuario=$(id -Gn "$usuario" 2>/dev/null) 

    for grupo in $grupos_usuario; do
        if [[ "$grupo" == "reprobados" || "$grupo" == "recursados" ]]; then
            return 0  # El usuario está en "reprobados" o "recursados"
        fi
    done
    return 1  # No pertenece a esos grupos
}