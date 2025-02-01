# Solicita el número de OUs (Organizaciones) a crear y el dominio.
$org_number = Read-Host "¿Cuántas organizaciones deseas crear?"
$domain = Read-Host "¿En qué dominio deseas crear las organizaciones? (Ejemplo: ejemplo.com)"

# Crear Organizaciones (Unidades Organizativas - OU)
for ($i = 1; $i -le $org_number; $i++) {
    $group_name = Read-Host "Nombre de la organización $($i):"
    # Crea la OU en el dominio especificado
    New-ADOrganizationalUnit -Name $group_name -Path "DC=$domain,DC=com"
}

# Pregunta al usuario si quiere crear nuevos usuarios o mover usuarios existentes a grupos
$option = Read-Host "¿Quieres crear usuarios o mover usuarios a los grupos? (C/M)"

if ($option -eq "C") {
    # Crear nuevos usuarios
    $user_number = Read-Host "¿Cuántos usuarios deseas crear?"
    $workgroup = Read-Host "Organización AD (OU) para agregar los usuarios:"
    
    for ($i = 1; $i -le $user_number; $i++) {
        $user_name = Read-Host "Nombre del usuario $($i):"
        $password = Read-Host -Prompt "Contraseña para $user_name" -AsSecureString
        
        # Crear usuario en la OU especificada
        New-ADUser -Name $user_name `
            -AccountPassword $password `
            -Enable $true `
            -Path "OU=$workgroup,DC=$domain,DC=com" `
            -UserPrincipalName "$user_name@$domain"
    }

} elseif ($option -eq "M") {
    # Mover usuarios existentes entre grupos
    $user_move_count = Read-Host "¿Cuántos usuarios deseas mover?"
    for ($i = 1; $i -le $user_move_count; $i++) {
        $user_name = Read-Host "Nombre del usuario a mover:"
        $target_group = Read-Host "Nombre del grupo de destino (OU):"
        
        # Obtén el DistinguishedName del usuario y muévelo
        $user = Get-ADUser -Identity $user_name
        Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=$target_group,DC=$domain,DC=com"
    }
}

# Crear Políticas de Grupo (GPO)
$gpo_count = Read-Host "¿Cuántas políticas de grupo deseas crear?"
for ($i = 1; $i -le $gpo_count; $i++) {
    $gpo_name = Read-Host "Nombre de la política de grupo $($i):"
    New-GPO -Name $gpo_name
}

# Asignar GPOs a OUs
Get-ADOrganizationalUnit -Filter *
$org_unit1 = Read-Host "Nombre de la OU para agregar la política de grupo 1:"
$org_unit2 = Read-Host "Nombre de la OU para agregar la política de grupo 2:"

$groupA = Read-Host "Nombre del GPO 1 a vincular:"
$groupB = Read-Host "Nombre del GPO 2 a vincular:"

New-GPLink -Name $groupA -Target "OU=$org_unit1,DC=$domain,DC=com"
New-GPLink -Name $groupB -Target "OU=$org_unit2,DC=$domain,DC=com"
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName RestrictRun -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun" -ValueName 1 -Type String -Value notepad.exe
# Con esto solo tendrán bloqueado el bloc de notas
Set-GPRegistryValue -Name "$groupB" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName DisallowRun -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupB" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" -ValueName 1 -Type String -Value notepad.exe
# Limitar el almacenamiento a 5 MB
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName EnableProfileQuota -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName MaxProfileSize -Type DWord -Value 5120
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUser -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUserTimeout -Type DWord -Value 10
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName ProfileQuotaMessage -Type String -Value "Superaste tus 5 MB de almacenamiento, libera antes de cerrar sesión"
# Limitar el almacenamiento a 10 MB
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName EnableProfileQuota -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName MaxProfileSize -Type DWord -Value 10240
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUser -Type DWord -Value 1
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName WarnUserTimeout -Type DWord -Value 10
Set-GPRegistryValue -Name "$groupA" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName ProfileQuotaMessage -Type String -Value "Superaste tus 5 MB de almacenamiento, libera antes de cerrar sesión"
# Configurar carpeta compartida para las organizaciones
New-Item -ItemType Directory -Name "Organizaciones" -Path "C:\"
New-SmbShare -Name "Organizaciones" -Path "C:\Organizaciones"
Grant-SmbShareAccess -Name "Organizaciones" -AccountName "Everyone" -AccessRight Full

# Vincular usuarios con la carpeta compartida
$user = Read-Host "Nombre del usuario a agregar a la carpeta compartida:"
Set-ADUser -Identity "$user" -ProfilePath "\\$env:COMPUTERNAME\Organizaciones\$($user)"

# Actualizar Políticas de Grupo en los equipos
Invoke-GPUpdate
gpupdate /force
