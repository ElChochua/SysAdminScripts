#!/bin/bash
source /media/sf_Ubuntu/Functions.sh
read -p "user" user
read -p "group" group
if user_in_other_group "$user" "$group"; then
    echo "⚠️ El usuario '$user' ya pertenece a otro grupo diferente a '$group'."
else
    echo "✅ El usuario puede ser registrado en '$group'."
fi