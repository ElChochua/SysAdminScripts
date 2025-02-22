#!/bin/bash
source /media/sf_shared/Funciones.sh
root_ip="192.168.1.10"
ip_reverse_zone=$(remove_last_byte_and_rev $root_ip)
echo $ip_reverse_zone